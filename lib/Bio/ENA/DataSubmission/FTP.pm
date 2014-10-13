package Bio::ENA::DataSubmission::FTP;

# ABSTRACT: module for uploading data to ENA FTP server

=head1 NAME

Bio::ENA::DataSubmission::FTP

=head1 SYNOPSIS

	

=head1 METHODS

=head1 CONTACT

path-help@sanger.ac.uk

=cut

use strict;
use warnings;
no warnings 'uninitialized';
use Moose;
use Net::FTP;
use File::Basename;

has 'server'    => ( is => 'rw', isa => 'Str',      required => 1 );
has 'username'  => ( is => 'rw', isa => 'Str',      required => 1 );
has 'password'  => ( is => 'rw', isa => 'Str',      required => 1 );
has 'files'     => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'directory' => ( is => 'rw', isa => 'Str',      required => 0 );
has 'error'     => ( is => 'rw', isa => 'Str',      required => 0 );

sub upload {
	my $self = shift;

	my $server   = $self->server;
	my $username = $self->username;
	my $password = $self->password;

	# check files exist first
	for my $file ( @{ $self->files } ){
		unless( -e $file ){
			$self->error( "Cannot find $file\n" );
			return 0;
		}
	}

	# open FTP connection
	my $ftp;
	unless ( $ftp = Net::FTP->new( $server ) ){
		$self->error( "Cannot connect to $server" );
		return 0;
	}

	# authenticate
	unless ( $ftp->login( $username, $password ) ) {
		$self->error( "Authentication failed for $server" );
		return 0;
	}

	$ftp->binary(); # set mode

	# create target directory unless it already exists
	my $dest; # destination on the server
	if ( defined $self->directory ){
		$dest = $self->directory;
		$ftp->mkdir( $self->directory );
	}

	for my $file ( @{ $self->files } ){
		my $target = $file;
		$target = $self->_server_target( $file );
		unless ( $ftp->put( $file, $target ) ){
			$self->error( "Failed to upload $file\n" );
			return 0;
		}
	}

	unless ( $ftp->quit ) {
		$self->error( $ftp->message );
		return 0;
	}

	return 1;
}

sub _server_target {
	my ( $self, $local ) = @_;

	my ( $filename, $directories, $suffix ) = fileparse( $local );
	return $self->directory . "/$filename" if ( defined $self->directory );
	return $filename;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;