package Net::Async::Redis::Subscription;

use strict;
use warnings;

# VERSION

=head1 NAME

Net::Async::Redis::Subscription - represents one subscription

=head1 DESCRIPTION

Instances are generated by the subscription methods such as L<Net::Async::Redis/subscribe>
and L<Net::Async::Redis/psubscribe>.

=cut

use Scalar::Util qw(weaken);

sub new {
    my ($class, %args) = @_;
    weaken($args{redis} // die 'Must be provided a Net::Async::Redis instance');
    bless \%args, $class;
}

=head2 events

Returns a L<Ryu::Source> representing the messages emitted by this subscription.

=cut

sub events {
    my ($self) = @_;
    $self->{events} ||= do {
        my $ryu = $self->redis->ryu->source(
            label => $self->channel
        );
        $ryu->completed->on_ready(sub {
            weaken $self
        });
        $ryu
    };
}

=head2 cancel

Cancel an existing subscription.

Normally called by L<Net::Async::Redis> itself once the subscription is no longer valid.

=cut

sub cancel {
    my ($self) = @_;
    my $f = $self->events->completed;
    $f->fail('cancelled') unless $f->is_ready;
    $self
}

=head2 redis

Accessor for the L<Net::Async::Redis> instance.

=cut

sub redis { shift->{redis} }

=head2 channel

The channel name for this instance.

=cut

sub channel { shift->{channel} }

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT' or not my $ev = $self->{events};
    $ev->completed->done unless $ev->completed->is_ready;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >> plus contributors as mentioned in
L<Net::Async::Redis/CONTRIBUTORS>.

=head1 LICENSE

Copyright Tom Molesworth 2015-2021. Licensed under the same terms as Perl itself.

