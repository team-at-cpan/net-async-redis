package Net::Async::Redis::Multi;

use strict;
use warnings;

# VERSION

=head1 NAME

Net::Async::Redis::Multi - represents multiple operations in a single Redis transaction

=head1 DESCRIPTION

Instances are generated by L<Net::Async::Redis/multi>.

=cut

use Scalar::Util qw(weaken);
use Log::Any qw($log);
use Syntax::Keyword::Try;

sub new {
    my ($class, %args) = @_;
    weaken($args{redis} // die 'Must be provided a Net::Async::Redis instance');
    bless \%args, $class;
}

sub exec {
    my ($self, $code) = @_;
    $self->$code;
    $self->redis->exec->then(sub {
        my @reply = @{$_[0]};
        my $success = 0;
        my $failure = 0;
        while(my $queued = shift @{$self->{queued_requests}}) {
            try {
                my $reply = shift @reply;
                $queued->done($reply) unless $queued->is_ready;
                ++$success
            } catch {
                $log->warnf("Failure during transaction: %s", $@);
                ++$failure
            }
        }
        Future->done(
            $success, $failure
        )
    }, sub {
        my ($err, $category, @details) = @_;
        for my $queued (splice @{$self->{queued_requests}}) {
            try {
                $queued->fail("Transaction failed", redis => 'transaction_failure') unless $queued->is_ready;
            } catch {
                $log->warnf("Failure during transaction: %s", $@);
            }
        }
        Future->fail($err, $category, @details);
    })->retain
}

=head2 redis

Accessor for the L<Net::Async::Redis> instance.

=cut

sub redis { shift->{redis} }

sub AUTOLOAD {
    my ($method) = our $AUTOLOAD =~ m{::([^:]+)$};
    die "Unknown method $method" unless exists $Net::Async::Redis::Commands::COMMANDS{$method};
    my $code = sub {
        my ($self, @args) = @_;
        local $self->redis->{_is_multi} = 1;
        push @{$self->{queued_requests}}, my $f = $self->redis->$method(@args)->then(sub {
            my ($resp) = @_;
            return $self->redis->future->set_label($method) if $resp eq 'QUEUED';
            Future->fail(@_)
        });
        $f
    };
    { no strict 'refs'; *$method = $code }
    $code->(@_);
}

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT' or not my $ev = $self->{queued_requests};
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2015-2018. Licensed under the same terms as Perl itself.

