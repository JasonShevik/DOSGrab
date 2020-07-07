##!/usr/bin/perl -w
use strict;
use LWP::UserAgent;
my($ua, $response, $mainContents, $thisLink, $check, $page, $thisContents, $downloadLink, $name);
my @links = ();

$ua = LWP::UserAgent->new(
	protocols_allowed 	=> ['http', 'https'],
	timeout 			=> 10,
	agent 			=> "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0", #Necessary otherwise 403 forbidden.
);

$page = 0;
while(1){
	$response = $ua->get('http://www.abandonia.com/en/game/all?page='.int($page));
	if($response->is_success){
		$mainContents = $response->decoded_content;
		while($mainContents =~ /<a href=\"\/en\/games\/(.*?)\.html\"/g){
			$thisLink = $1;
			if(scalar(@links) == 0){
				push(@links, $thisLink);
			}else{
				$check = 1;
				for(my $i = 0; $i<scalar(@links);++$i){
					if($thisLink eq $links[$i]){
						$check = 0;
						last;
					}
				}
				if($check){
					push(@links, $thisLink);
				}
			}
		}
		if($mainContents =~ /current\">(.*?)<\/strong/g){
			if($page - $1 == 0){
				last;
			}
		}
		$page++;
	}else{
		die $response->status_line;
	}
}

for(my $i = 0; $i<scalar(@links);++$i){
	$downloadLink = &getDownloadLink($links[$i]);
	if($downloadLink =~ /\?game=(.*?)\&/){
		$name = $1;
	}
	$ua->get($downloadLink, ':content_file' => $i." - ".$name.'.zip');
}

sub getDownloadLink{
	$response = $ua->get('http://www.abandonia.com/en/games/'.$_[0]);
	if($response->is_success){
		$thisContents = $response->decoded_content;
		if($thisContents =~ /game_downloadpicture\"><a href=\"\/en\/downloadgame\/(.*?)\">/){
			$response = $ua->get('http://www.abandonia.com/en/downloadgame/'.$1);
			if($response->is_success){
				$thisContents = $response->decoded_content;
				if($thisContents =~ /files\.abandonia\.com\/download\.php(.*?)\"/){
					return "http://files.abandonia.com/download.php".$1;
				}
			}else{
				die $response->status_line;
			}
		}
	}else{
		die $response->status_line;
	}
}
