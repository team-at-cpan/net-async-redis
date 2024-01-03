package Net::Async::Redis::Multi;

use strict;
use warnings;

# VERSION

=head1 NAME

Net::Async::Redis::Multi - represents multiple operations in a single Redis transaction

=head1 DESCRIPTION

Instances are generated by L<Net::Async::Redis/multi>.

=cut

use Syntax::Keyword::Try;
use Syntax::Keyword::Dynamically;
use Future::AsyncAwait;
use Scalar::Util qw(weaken blessed);
use Log::Any qw($log);

sub new {
    my ($class, %args) = @_;
    $args{queued_requests} //= [];
    weaken($args{redis} // die 'Must be provided a Net::Async::Redis instance');
    bless \%args, $class;
}

async sub exec {
    my ($self, $code) = @_;

    try {
        my $f = $self->$code;
        $f->retain if blessed($f) and $f->isa('Future');

        $log->tracef('MULTI exec');
        dynamically $self->redis->{_is_multi} = $self->redis->{multi_queue};
        my ($exec_result) = await $self->redis->exec;
        $self->redis->{multi_queue}->finish;
        my @reply = $exec_result->@*;
        my $success = 0;
        my $failure = 0;
        while(@reply) {
            try {
                my $reply = shift @reply;
                my $queued = shift @{$self->{queued_requests}} or die 'invalid queued request';
                $queued->done($reply) unless $queued->is_ready;
                ++$success
            } catch {
                $log->warnf("Failure during transaction: %s", $@);
                ++$failure
            }
        }
        return $success, $failure;
    } catch {
        my $err = $@;
        $log->errorf('Failed to complete multi - %s', $err);
        for my $queued (splice @{$self->{queued_requests}}) {
            try {
                $queued->fail("Transaction failed", redis => 'transaction_failure') unless $queued->is_ready;
            } catch {
                $log->warnf("Failure during transaction: %s", $@);
            }
        }
        die $@;
    }
}

=head2 redis

Accessor for the L<Net::Async::Redis> instance.

=cut

sub redis { shift->{redis} }

use Sub::Util qw(set_subname);

sub AUTOLOAD {
    my ($method) = our $AUTOLOAD =~ m{::([^:]+)$};

    # We only need to check this once
    die "Unknown method $method" unless Net::Async::Redis::Commands->can($method);

    my $code = async sub {
        my ($self, @args) = @_;
        my $f = $self->redis->future->set_label($method);
        push @{$self->{queued_requests}}, $f;
        my $ff = do {
            # $self->redis->{_is_multi} //= 0;
            dynamically $self->redis->{_is_multi} = $self->redis->{multi_queue};
            $self->redis->$method(@args);
        };
        my ($resp) = await $ff;
        return await $f if $resp eq 'QUEUED';

        # my $addr = refaddr($f);
        # extract_by { $addr == refaddr($_) } @{$self->{queued_requests}};
        $f->fail($resp);
        die $resp;
    };
    set_subname $method => $code;
    { no strict 'refs'; *$method = sub { $code->(@_)->retain } }
    $code->(@_)->retain;
}

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT' or not $self->{queued_requests};

    for my $queued (splice @{$self->{queued_requests}}) {
        try {
            $queued->cancel;
        } catch {
            $log->warnf("Failure during cleanup: %s", $@);
        }
    }
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >> plus contributors as mentioned in
L<Net::Async::Redis/CONTRIBUTORS>.

=head1 LICENSE

Copyright Tom Molesworth 2015-2024. Licensed under the same terms as Perl itself.

