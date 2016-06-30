#!/usr/bin/perl

use LWP::Simple;
use LWP;
use strict;

# use Shell::GetEnv;
# use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Digest::MD5;
use File::Copy;

my $base_url = "http://localhost:8080/proteios/resource/";
my $userinfo = "username=bils&password=bils";

my $folder  = "/srv/www/thegpm/files";
my $user    = $userinfo;
my $project = "label free bils";

# initialise
chdir $folder or die "Couldn't change to uploaddir";

# look for all files
my @files = glob("*.mzML.gz");
foreach my $filename (@files) {
	print("mzML file:$filename\n");

	if ( ( length($project) ) > 0 ) {
		my $projectid = getProteiosProjectId( $user, $project );
		die "Project couldn't be registered" unless $projectid >= 0;
		my $filesize = -s $filename;

		# Now register the file!
		registerRemoteFileInProteios( $user, $projectid, $filename, 0,
			$filesize, "", "http://localhost/files/$filename",
			"false", $filesize );

		# Also register the uncompressed file if it is a .gz!
		if ( $filename =~ /(.*)\.gz$/ ) {
			my $decompname = $1;
			open( GZLIST, "gzip --list $filename |" );
			my @res = (<GZLIST>);
			close(GZLIST);
			@res[1] =~ /\s+\d+\s+(\d+)\s.+/;
			if ( length($1) ) {
				print "Decompressed size $1\n";
				registerRemoteFileInProteios( $user, $projectid, $decompname, 0,
					$1, "", "http://localhost/files/$filename",
					"true", $filesize );
			}
			else {
				die "Couldn't get uncompressed size from $filename";
			}
		}
		if ( $filename =~ /(.*)\.mzML\.gz$/ ) {
			my $mgfgz   = "$1\.mgf.gz";
			my $mgffile = "$1\.mgf";
			if ( -e "$mgfgz" ) {
				print "Found MGF:$mgffile\n";
				open( GZLIST, "gzip --list $mgfgz |" );
				my @res = (<GZLIST>);
				close(GZLIST);
				@res[1] =~ /\s+\d+\s+(\d+)\s.+/;
				if ( length($1) ) {
					print "Decompressed size $1\n";
					registerRemoteFileInProteios( $user, $projectid, $mgffile,
						0, $1, "", "http://localhost/files/$mgfgz",
						"true", $filesize );
				}
				else {
					die "Couldn't get uncompressed size from $mgffile";
				}
				my $infofile = $filename . ".info";
				if ( -e $infofile ) {
					print "Found info file:$infofile\n";
					my $filecontent = slurpFileContent($infofile);
					uploadPhysicalFileToProteios( $user, $projectid, $infofile,
						"true", $filecontent );
				}
			}
		}
	}
}
print "All done\n";

sub getIdFromTabResponse {
	my $resp = shift;
	my @content;
	my @line = split( "\n", $resp );
	if ( $#line >= 1 ) {
		@content = split( "\t", $line[1] );
		return $content[0];
	}
	print $#line;
	return "-1";
}

sub md5sum {
	my $file   = shift;
	my $digest = "";

	eval {
		open( FILE, $file ) or die "Can't find file $file\n";
		binmode FILE;
		my $ctx = Digest::MD5->new;
		$ctx->addfile(*FILE);
		$digest = $ctx->hexdigest;
		close(FILE);
	};

	if ($@) {
		print $@;
		return "";
	}
	return $digest;
}

sub uploadPhysicalFileToProteios {
	my $user        = shift;
	my $projectid   = shift;
	my $filename    = shift;
	my $compress    = shift;
	my $filecontent = shift;
	my $url         = $base_url . "projects/$projectid/files\?&select=*&whereName==$filename";
	my $browser = LWP::UserAgent->new;
	my $req     = new HTTP::Request( 'GET', $url );
        my $filetype= "";                     
	$req->authorization_basic('bils','bils');                                  
	my $response = $browser->request($req);
	if ( !$response->is_success ) {
		print "Error getting $url. Retrying after waiting";
		sleep 300;
		$response = $browser->request($req);
	}
	die "Error getting $url" unless $response->is_success;
	my $fileid = getIdFromTabResponse($response->content);
	if ( $fileid == -1 ) {
		my $url3 = $base_url . "projects/$projectid/files/\?$user";
		my $req4 = new HTTP::Request( 'PUT', $url3 );
		$req4->authorization_basic('bils','bils');                                  		
		$req4->content("Name\tCompressed\tMimeType\tFileType\n$filename\t$compress\ttext/plain\t$filetype\n");
		my $browser   = LWP::UserAgent->new;
		my $response3 = $browser->request($req4);
	}
	# get the file id and upload the file content
	$req     = new HTTP::Request( 'GET', $url );
	$req->authorization_basic('bils','bils'); 
	$response = $browser->request($req);
	die "Error getting $url" unless $response->is_success;
	$fileid = getIdFromTabResponse($response->content);
	my $url4   = $base_url . "files/$fileid/\?";
	my $req6 = new HTTP::Request( 'PUT', $url4 );
	print "Uploading $filename\n";
	$req6->content($filecontent);
	$req6->authorization_basic('bils','bils');
	my $response4 = $browser->request($req6);
	die "Error uploading $filename" unless $response4->is_success;
	unlink($filename);
}

sub slurpFileContent {
	my $filename = shift;
	local $/ = undef;
	open FILEIN, "$filename"
	  or die "Couldn't open file $filename for upload";
	binmode FILEIN;
	my $filecontent = <FILEIN>;
	close FILEIN;
	return $filecontent;
}

sub webDAVUpload {
	my $filename      = shift;
	my $mountpath     = shift;
	my $size          = shift;
	my $uploadcommand = "cp $filename $mountpath";
	print "command:$uploadcommand\n";

	my @parts = split( "/", $mountpath );
	my $folder = $parts[0];

	for ( my $count = 1 ; $count <= $#parts - 1 ; $count++ ) {
		$folder = $folder . "/" . $parts[$count];
		if ( !( -e $folder ) ) {
			print("mkdir $folder\n");
			mkdir $folder;
		}
	}

	# Now upload the file
	system($uploadcommand) == 0
	  or system($uploadcommand)
	  or print "Upload failed: $?\n";
	sleep(10);

	# Check size of uploaded file
	my $lsres   = "";
	my $counter = 0;
	do {
		$counter++;
		sleep(5);
		open( NGLSRES, "ls -l --time-style=long-iso $mountpath |" );
		$lsres = (<NGLSRES>);
		close(NGLSRES);
	} until ( !( $lsres =~ /^ls: cannot.*/ ) || ( $counter > 50 ) );
	print "ls result:$lsres\n";
	$lsres =~ /.*\s(\d+)\s\d{4}-.+/;
	my $newsize = $1;
	print "ls counter:$counter\n";
	if ( $counter > 50 ) {
		print "Couldn't get remote file size.";
		return (-1);
	}
	if ( $newsize != $size ) {
		my $remove;
		print "Uploaded size $newsize not matching $size\n";
		$remove = "rm $mountpath";
		system($remove);
		if ( system($uploadcommand) != 0 ) {
			print "Failed to upload file using $uploadcommand :\n$?\n";
			return -1;
		}
	}
	return 0;
}

sub getProteiosProjectId {
	my $user    = shift;
	my $project = shift;

	# Now the Proteios registration
	my $url      = $base_url . "projects\?$user\&select=*&whereName==$project";
	my $response = get $url;
	die "Error getting $url" unless defined $response;
	my $projectid = getIdFromTabResponse($response);
	if ( $projectid == -1 ) {
		my $browser = LWP::UserAgent->new;
		my $url2    = $base_url . "projects\?$user";
		my $req     = new HTTP::Request( 'PUT', $url2 );
		$req->content("Name\n$project\n");
		my $response2 = $browser->request($req);
		die "Error putting project $project to $url2\n"
		  unless $response2->is_success;
		$response = get $url;
		die "Error getting $url" unless defined $response;
		$projectid = getIdFromTabResponse($response);
	}
	print "Project ID:" . $projectid . "\n";
	return $projectid;
}

sub registerRemoteFileInProteios {
	my $user       = shift;
	my $projectid  = shift;
	my $filename   = shift;
	my $md5        = shift;
	my $size       = shift;
	my $desc       = shift;
	my $uri        = shift;
	my $compressed = shift;
	my $compSize   = shift;

	# First check if there is already a file registered
	my $browser= LWP::UserAgent->new;
    
    $browser->credentials("localhost:8080", 'Proteios', 'bils', 'bils');
	
	my $filetype ="file";
	if ( $filename =~ /(.*)\.mzML$/ ) {
		$filetype = "org.proteios.core.FileType.MZML";
	}
		if ( $filename =~ /(.*)\.mgf$/ ) {
		$filetype = "org.proteios.core.FileType.MGF_PEAK_LIST";
	}
    # First check if there is already a file registered
	my $url = $base_url
	  . "projects/$projectid/files\?&select=*&whereName==$filename";
	my $req = new HTTP::Request( 'GET', $url );
	# $req->authorization_basic('root',$proteiospw);
	my $response = $browser->request($req);
	if ( !$response->is_success ) {
		print "Error getting $url. Retrying after waiting";
		sleep 300;
		$response = $browser->request($req);
	}
	die "Error getting $url" unless $response->is_success;
	my $fileid = getIdFromTabResponse($response->content);

	# Didn't exist:
	if ( $fileid == -1 ) {
		print "Registering file\n";
		my $url3         = $base_url . "projects/$projectid/files/\?";
		$req          = new HTTP::Request( 'PUT', $url3 );
		my $headerstring =
"Name\tFileType\tMd5\tSizeInBytes\tDescription\tUniformResourceIdentifier\tCompressed\tCompressedSizeInBytes\n";
		my $contentstring =
		  $headerstring
		  . "$filename\t$filetype\t$md5\t$size\t$desc\t$uri\t$compressed\t$compSize";
		print "$contentstring\n";
		$req->content($contentstring);
		my $response3 = $browser->request($req);
		$url3 =~ s/password=.*&/password=&/;
		print "$url3 status " . $response3->status_line . "\n";
		die "$url3 error:", $response3->status_line
		  unless $response3->is_success;
	}
	else {
		print "Updating existing file\n";

		# POST to update
		my $browser2 = LWP::UserAgent->new;
                $browser2->credentials("localhost:8080", 'Proteios', 'bils', 'bils');

		my $url4     = $base_url . "files/$fileid";
		my $req2     = new HTTP::Request( 'POST', $url4 );
		my $updated  =
"&Name=$filename&FileType=$filetype&Md5=$md5&SizeInBytes=$size&Description=$desc&UniformResourceIdentifier=$uri&Compressed=$compressed&CompressedSizeInBytes=$compSize";
		my $contents = $updated;
		print "Content:$contents";
		$req2->content($contents);
		$req2->content_type('application/x-www-form-urlencoded');
		my $response4 = $browser2->request($req2);
		$url4 =~ s/password=.*&/password=&/;
		print "$url4 status " . $response4->status_line . "\n";
		die "$url4 error:", $response4->status_line
		  unless $response4->is_success;
	}
}

