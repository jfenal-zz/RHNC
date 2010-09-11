package RHNC::Schedule;

use warnings;
use strict;

=head1 NAME

RHNC::Schedule - Red Hat Network Client - Schedules handling

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use RHNC::Schedule;

    my $foo = RHNC::Schedule->new();
    ...

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 _uniqueid

Returns a C<RHNC::Schedule> object instance's unique id (id).

  $id = $object->_uniqueid;

=cut

sub _uniqueid {
    my ($self) = @_;
    return $self->{id};
}

=head2 new

Create a new RHNC::Schedule action object.

Not of use unless you know what you do.

=cut

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};

    bless $self, $class;

    %{$self} = @args;

    return $self;
}

=head2 actions

Returns a list of actions.

By default, return all actions (completed, in progress, failed and
archived).

Using an argument, you can request only the specific actions.

  $action_arrayref = RHNC::Schedule->actions( $rhnc );
  $action_arrayref = RHNC::Schedule->actions( $rhnc, 'all' );
  $action_arrayref = RHNC::Schedule->actions( $rhnc, 'completed' );
  $action_arrayref = RHNC::Schedule->actions( $rhnc, 'archived' );
  $action_arrayref = RHNC::Schedule->actions( $rhnc, 'failed' );
  $action_arrayref = RHNC::Schedule->actions( $rhnc, 'in progress' );

=cut
my %schedule_action_method = (
    undef      => 'listAllActions',
    ''         => 'listAllActions',
    all        => 'listAllActions',
    archived   => 'listArchivedActions',
    completed  => 'listCompletedActions',
    failed     => 'listFailedActions',
    inprogress => 'listInProgressActions',
);

sub actions {
    my ($self, $rhnc, @args ) = RHNC::_get_self_rhnc_args(__PACKAGE__, @_);
    my $action_type = shift @args;

    my $list;
    if (defined $action_type) {
        $action_type = lc $action_type;
        $action_type =~ s/[\s_]//g;

        my $method = $schedule_action_method{$action_type};
        $list = $rhnc->call("schedule.$method");
    }
    else {
        $list = $rhnc->call('schedule.listAllActions');
    }

    my $actions = [];
    foreach my $action (@$list) {
        push(
            @$actions,
            RHNC::Schedule->new(
                rhnc => $rhnc,
                %{$action},
            )
        );
    }

    return $actions;
}

=head2 as_string

Return a printable string from a L<RHNC::Schedule> object.

  print $sched->as_string;

=cut

sub as_string {
    my ($self) = @_;
    my $str = "$self->{id},\"$self->{type}\",\"$self->{scheduler}\",";
    $str .= $self->{earliest}->value();
    $str .= ",\"$self->{name}\"\n";

    return $str;
}

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-rhn-session at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHNC-Session>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 AUTHOR

Jerome Fenal, C<< <jfenal at free.fr> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RHNC::Schedule


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RHNC-Session>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RHNC-Session>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RHNC-Session>

=item * Search CPAN

L<http://search.cpan.org/dist/RHNC-Session/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2009 Jerome Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of RHNC::Schedule
