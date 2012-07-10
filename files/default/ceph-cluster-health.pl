#!/usr/bin/perl

use strict;
use warnings;

my $alert_email = shift || &usage;
my $warning_email = shift || &usage;
my $cluster = shift || &usage;

my @health = qx{ /usr/bin/ceph health --debug-ms 0 };

foreach my $line (@health) {
	if ( $line =~ /HEALTH_OK/ ) {
		print "Ceph health ok\n";
	}elsif ( $line =~ /HEALTH_WARN/ ) {
		print "Ceph health warning\n";
		&send_alert($warning_email,join('', @health));
	}elsif ( $line =~ /HEALTH_CRIT/ ) {
		print "Ceph health CRITICAL!\n";
		&send_alert($alert_email,join('', @health));
	}
}

sub usage {
	die "$0: <alert email> <cluster>\n";
}

sub send_alert {
        use Net::SMTP;

        my $alert_email = shift;
        my $alert = shift;

        my $smtp = Net::SMTP->new('localhost');
        $smtp->mail('do-not-reply@dreamhost.com');
        $smtp->to($alert_email);
        $smtp->to('kyle.bader@dreamhost.com');
        $smtp->data();
        $smtp->datasend("From: Dream Objects Ceph Health Bot <do-not-reply\@dreamhost.com>\n");
        $smtp->datasend("To: $alert_email\n");
        $smtp->datasend("Subject: $cluster Ceph Health Alert\n");
        $smtp->datasend("\n");
        $smtp->datasend($alert);
        $smtp->dataend();
        $smtp->quit;
}
