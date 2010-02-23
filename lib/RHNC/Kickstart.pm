package RHNC::Kickstart;

use warnings;
use strict;

=head1 NAME

RHNC::Kickstart - Red Hat Network Client - Kickstart handling

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use RHNC::Kickstart;

    my $foo = RHNC::Kickstart->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 createProfile

* string sessionKey
* string profileLabel - Label for the new kickstart profile.
* string virtualizationType - none, para_host, qemu, xenfv or xenpv.
* string kickstartableTreeLabel - Label of a kickstartable tree to associate the new profile with.
* string kickstartHost - Kickstart hostname (of a satellite or proxy) used to construct the default download URL for the new kickstart profile.
* string rootPassword - Root password.

=cut

sub createProfile {
}

=head2 get

=cut

sub get {


}


=head1 AUTHOR

Jérôme Fenal, C<< <jfenal at redhat.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rhn-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHNC-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RHNC::Kickstart


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

1; # End of RHNC::Kickstart
