#!/usr/bin/perl
# PicoLix Design 

use Image::Magick;
use File::Basename qw/ fileparse /;
use strict;

our $WB_TEXT = "< WB.txt";
our $RGB_TEXT = "< RGB.txt";
our $JRGB_TEXT = "< JRGB.txt";

our @color_hue = ();
our @color_meido = ();
our @color_saido = ();
our @color_cnt = ();
our @color_score = ();

my $file = $ARGV[0];
my $top_num = 3;

if(!(-e $file)){
	print "error: no input file\n";
	exit(-1);
}

if($ARGV[1] ne ""){
	$top_num = $ARGV[1];
}

my ($base,$dir,$ext) = fileparse($file, qr/\..+$/);

my @al = (0.00, 0.89, 0.93, 0.61, 0.28, 0.22, 0.18, 0.08, 0.01, 0.35);
#my @al = (1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0);

#画像の読み込み
my $img = Image::Magick->new;
$img->Read($file);

#画像をぼかす
$img->Blur(radius=>13, sigma=>13);
#画像を50x50に縮小する
$img->Scale(width=>50, height=>50);
#画像を16色に減色する
$img->Quantize(colors=>16, dither=>'False');

my @h_cnt = ();
my @color_rgb = ();
for(my $x = 0 ; $x < 50 ; $x++){
	for(my $y = 0 ; $y < 50 ; $y++){
		my ($r, $g, $b, $ugh) = split ',', $img->Get("pixel[$x,$y]");

		#for Q=16 comment out
		#$r = int($r / 256);	
		#$g = int($g / 256);
		#$b = int($b / 256);
	
		my ($hued,$meido,$saido) = hue($r,$g,$b);
		$h_cnt[$hued] += 1;

		my $rgb = sprintf("%3d-%3d-%3d",$r,$g,$b);

	 	my $col_flg = 0;
	 	my $i;
	 	for($i = 0 ; $i < 16 ; $i++){
	 		if ($color_rgb[$i] eq $rgb){
	 			$color_cnt[$i]++;
	 			$col_flg = 1;
	 			last;
	 		}
	 		if($color_rgb[$i] eq ""){
		 			last;
 			}
 		}
 		if($col_flg == 0){
 			$color_rgb[$i] = $rgb;
 			$color_cnt[$i] = 1;
 			$color_hue[$i] = $hued;
 			$color_meido[$i] = $meido;
 			$color_saido[$i] = $saido;
 		}
 	} 
}

#１６色のスコア計算

for(my $i = 0 ; $i < 16 ; $i++){
	my ($c1,$c2);

	if($color_hue[$i] > 0){
		$c1 = (2 * ($color_cnt[$i] /2500))**2;
		$c2 = ((2 * $al[int($color_hue[$i] /36)] + $color_meido[$i] + $color_saido[$i]) /4)**2;
	}else{
		#モノクロは適当に抑える
		$c1 = ($color_cnt[$i] / 2500)**2 /1000;
		$c2 = (($color_meido[$i] + $color_saido[$i]) /4)**2 /10;
	}
	$color_score[$i] = $c1 + $c2;
}

&bubble_sort();

my (@color_16_name,@color_full_name);
for(my $i = 0 ; $i < 16; $i++){
	$color_16_name[$i] = colorname($color_rgb[$i]);
	$color_full_name[$i] = colorname($color_rgb[$i],"J");
}

my $msg_fmt = "%2d: %4.3f %4d %11s %3d %3.2f %3.2f %6s %s\n";
my $msg_header = "\nNo: SCORE  CNT  R   G   B 色相 明度 彩度    色  色名 
---------------------------------------------------------------\n";

print $msg_header;
for(my $i = 0 ; $i < 16 ; $i++){
	my $msg = sprintf($msg_fmt,$i+1,
		$color_score[$i],$color_cnt[$i],$color_rgb[$i],
		$color_hue[$i],$color_meido[$i],$color_saido[$i],
		$color_16_name[$i],$color_full_name[$i]);
	print $msg;
}

my @color_16_name_b = @color_16_name;
my @color_full_name_b = @color_full_name;
my @color_cnt_b = @color_cnt;
my @color_hue_b = @color_hue;
my @color_meido_b = @color_meido;
my @color_saido_b = @color_saido;
my @color_score_b = @color_score;
my @color_rgb_b = @color_rgb;


#連続同一色は前につめる。
my $max = 15;
for(my $i = 0 ; $i < $max; $i++){
	if (($color_16_name[$i] eq $color_16_name[$i+1])){
		for(my $j = $i + 1 ; $j < 16 ; $j++){
			$color_16_name[$j] = $color_16_name[$j+1];
			$color_full_name[$j] = $color_full_name[$j+1];
			$color_cnt[$j] = $color_cnt[$j+1];
			$color_hue[$j] = $color_hue[$j+1];
 			$color_meido[$j] = $color_meido[$j+1];
 			$color_saido[$j] = $color_saido[$j+1];
			$color_score[$j] = $color_score[$j+1];
			$color_rgb[$j] = $color_rgb[$j+1];
		}
		$i--;
		$max--;
	}
}

#全て同一色の時2,3色目データ戻し
if($color_16_name[2] eq ""){
	for(my $i = 1 ; $i < 3; $i++){
		$color_16_name[$i] = $color_16_name_b[$i];
		$color_full_name[$i] = $color_full_name_b[$i];
		$color_cnt[$i] = $color_cnt_b[$i];
		$color_hue[$i] = $color_hue_b[$i];
		$color_meido[$i] = $color_meido_b[$i];
		$color_saido[$i] = $color_saido_b[$i];
		$color_score[$i] = $color_score_b[$i];
		$color_rgb[$i] = $color_rgb_b[$i];
	}
}

#TOP3色
print $msg_header;
for(my $i = 0 ; $i < $top_num ; $i++){
	my $msg = sprintf( $msg_fmt,$i+1,
			$color_score[$i],$color_cnt[$i],$color_rgb[$i],
			$color_hue[$i],$color_meido[$i],$color_saido[$i],
			$color_16_name[$i],$color_full_name[$i]);
	print $msg;
}


#3色キャンディー画像生成
my @col;
for(my $i = 0 ; $i < 3 ; $i++){
	my @dat = split(/-/, $color_rgb[$i]);
	$col[$i] = sprintf("#%02X%02X%02X",$dat[0],$dat[1],$dat[2]);
}

undef $img;

$img = Image::Magick->new;
$img->Set(size=>"171x108");
$img->ReadImage('xc:white');

$img->Draw(primitive=>'rectangle', points=>"0,0 56,107",stroke=>$col[1],fill=>$col[1]);
$img->Draw(primitive=>'rectangle', points=>"57,0 113,107",stroke=>$col[0],fill=>$col[0]);
$img->Draw(primitive=>'rectangle', points=>"114,0 170,107",stroke=>$col[2],fill=>$col[2]);

$img->Modulate(brightness=>100, saturation=>150, hue=>100);
$img->MotionBlur(radius=>10, sigma=>15, angle=>45);
$img->Resize(width=>40, height=>28, blur=>0.7);

$img->Write($base . "-candy.png");


exit;


################################################################
#色相、明度、彩度 17,37,60,113,165,181,202,259,310,341,360
sub hue {
	my ($r,$g,$b) = @_;

	my $maximum = max($r, $g, $b);
	my $minimum = min($r, $g, $b);
	my $saturation;
	my $hue;
	
	if($maximum > 0){
		$saturation = ($maximum - $minimum) / $maximum;
		if($saturation>0){
			if($maximum == $r){
					$hue = 60*(($g - $b) / ($maximum - $minimum));
			}elsif($maximum == $g){
					$hue = 60*(2 + ($b - $r) / ($maximum - $minimum));
			}elsif($maximum == $b){
					$hue = 60*(4 + ($r - $g) / ($maximum - $minimum));
			}
			if($hue < 0){
				$hue += 360;
			}
		}else{
			$hue = 0;
		}
	}else{
		$saturation = 0;
		$hue = 0;
	}
	$hue = int($hue);
	if($hue > 360 || (abs($r - $g) < 10 && abs($r - $b) < 10 && abs($g - $b) < 10)){
		$hue = 0;
	}

	return $hue,$maximum/255,$saturation;
}

sub max {
	my @data = @_;
	
	return if @data == 0;
	
	my $max = shift @data;
	
	foreach my $val (@data) {
		if ($max < $val) {
			$max = $val;
		}
	}
	return $max;
}

sub min {
	my @data = @_;
	
	return if @data == 0;
	
	my $min = shift @data;
	foreach my $val (@data) {
		if ($min > $val) {
			$min = $val;
		}
	}
	return $min;
}

sub colorname {
	my ($color_rgb,$mode) = @_;
	my ($r,$g,$b) = split(/-/, $color_rgb);

	if ($mode eq "J"){
		open (RGB, $JRGB_TEXT) ||  die "cannot open $RGB_TEXT.\n";
	}else{
		if(abs($r - $g) < 10 && abs($r - $b) < 10 && abs($g - $b) < 10){
			open (RGB, $WB_TEXT) ||  die "cannot open $WB_TEXT.\n";
		}else{
			open (RGB, $RGB_TEXT) ||  die "cannot open $RGB_TEXT.\n";
		}
	}
	
	my $score = 65536 * 3;
	my $result_name;

	while (<RGB>) {
		my ($tmp_r, $tmp_g, $tmp_b, $tmp_name) = split(/\s+/);
		my $tmp_score = ($tmp_r - $r)**2 + ($tmp_g - $g)**2 + ($tmp_b - $b)**2;
		if ($tmp_score < $score) {
			$score = $tmp_score;
			$result_name = $tmp_name;
		}
	}
	close (RGB);
	return $result_name;
}

sub bubble_sort {
	my ($i,$j);
	for($i = 0; $i < 16; $i++) {
		for ($j = $i + 1; $j < 16; $j++) {
			if ($color_score[$i] < $color_score[$j]) { 
				&swap_value($i,$j);
			}
		}
	}
} 

sub swap_value {
	my ($i,$j) = @_;
	my $tmp;
	
	$tmp = $color_score[$i];
	$color_score[$i] = $color_score[$j];
	$color_score[$j] = $tmp;
	
	$tmp = $color_cnt[$i];
	$color_cnt[$i] = $color_cnt[$j];
	$color_cnt[$j] = $tmp;
	
	$tmp = $color_rgb[$i]; 
	$color_rgb[$i] = $color_rgb[$j]; 
	$color_rgb[$j] = $tmp;

	$tmp = $color_hue[$i]; 
	$color_hue[$i] = $color_hue[$j];
	$color_hue[$j] = $tmp; 

	$tmp = $color_meido[$i]; 
	$color_meido[$i] = $color_meido[$j];
	$color_meido[$j] = $tmp; 
	
	$tmp = $color_saido[$i]; 
	$color_saido[$i] = $color_saido[$j];
	$color_saido[$j] = $tmp; 
}
