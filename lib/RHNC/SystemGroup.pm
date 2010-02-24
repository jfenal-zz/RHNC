package RHNC::SystemGroup;

use warnings;
use strict;
use Data::Dumper;
use Params::Validate;
use RHNC;

use base qw( RHNC );
use vars qw( $AUTOLOAD %properties %valid_prefix );

=head1 NAME

RHNC::SystemGroup - Red Hat Network Client - SystemGroup handling

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use RHNC::SystemGroup;

    my $foo = RHNC::SystemGroup->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 new

Constructor

=cut

use constant {
    MANDATORY => 0,
    DEFAULT   => 1,
    VALIDATE  => 2,
    TRANSFORM => 3,
};

my %valid_prefix = map { $_ => 1 } qw( Dr. Hr. Miss
  Mr. Mrs. Sr. );
my %properties = (
    id           => [ 0, undef, undef, undef ],
    rhnc         => [ 0, undef, undef, undef ],
    name         => [ 1, undef, undef, undef ],
    description  => [ 1, undef, undef, undef ],
    org_id       => [ 0, undef, undef, undef ],
    system_count => [ 0, undef, undef, undef ],
);

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};

    my %v = map { $_ => 0 } ( keys %properties );

    my %p = validate( @args, \%v );

    for my $i ( keys %properties ) {
        $self->{$i} = $p{$i};
    }

    bless $self, $class;

    return $self;

}


=head2 create

Persist system group

=cut
sub create {
    my ( $self, @args ) = @_;

#   $self = ref($self) || $self;
                if ( !ref $self ) {
                $self = RHN::SystemGroup->new(@args);
                    }

    my $res = $self->{rhnc}->call(
    'systemgroup.create',
    $self->{name},
    $self->{description},
);


}

=head2 list


Can work in OO context if you have already a SystemGroup at hand.

  @orgs = $org->list();

More likely in package context :

  @orgs = RHNC::SystemGroup->list( $RHNC );  # Need to specify a RHN client

=cut

sub list {
    my ( $self, $parm ) = @_;

    my $rhnc;
    if ( ref $self ) {    # OO context
        $rhnc = $self->{rhnc};
    }
    else {                # package context
        $rhnc = $parm;
    }

    my $res = $rhnc->call('systemgroup.listAllGroups');
    my @list;

    print STDERR Dumper( \@list );

    foreach my $g (@list) {
        my $sg = RHNC::SystemGroup->new(
            id           => $g->{id},
            name         => $g->{name},
            description  => $g->{description},
            org_id       => $g->{org_id},
            system_count => $g->{system_count},
        );
    }

}

=head1 AUTHOR

Jérôme Fenal, C<< <jfenal at redhat.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rhn-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHNC-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RHNC::SystemGroup


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


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jérôme Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of RHNC::SystemGroup
