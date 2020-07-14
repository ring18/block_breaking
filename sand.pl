#htmlのタグの中にspanタグを挟むスクリプト

use warnings;
use strict;
use utf8;
use feature 'state';
use Encode;
binmode STDOUT, ":utf8";


my $inp = join "", <STDIN>;

#コメントウザいので抜く
$inp =~ s/<!--.*?-->//sg;

#エンコードがらみの話 utf8へ
$inp =~ s/(<meta(.*?) charset=)(.*?)>/$1UTF-8>/s
$inp =~ m;(.*?)<body(.*?)>(.*?)</body>(.*?);s;

my ($st1,$st2,$st3,$st4) = ($1,$2,$3,$4);

#body の中を探る
$st3 = &tag_sandwitcher($st3);
print "$st3";

my $ret = "$st1"."<body"."$st2".">"."$st3"."</body>"."$st4";

print "$ret"."\n";







#&tag_sandwitcher($st) ->$st の中を見て コンテンツをspanで挟むサブルーチン
#いじった$stを返す

sub tag_sandwitcher {
    state $cnt = 0;
    my $st = shift;
    my $ret;
    @_ = split //,$st;
    #入れ子を飛ばすためのフラグ
    my $f = 0;
    for (my $i = 0; $i < length($st); $i++) {
        if($_[$i] =~ /[<>]/){
            #入れ子発見
            $f ^= 1;
            $ret .= $_[$i];
        } elsif (($_[$i] eq '&') and !($f & 1)){
            #特殊文字処理
            $ret .= '<span id="_'."$cnt".'">'.'&';
            $cnt += 1;
            $f ^= 2;
        } elsif (($f & 2) and !($f & 1)){
            #特殊文字処理
            if ($_[$i] eq ';') {
                $ret .= ';'.'</span>';
                $f ^= 2;
            } else {
                $ret .= $_[$i]
            }
        } elsif(($_[$i] =~ /\s/) or ($f & 1)){
            #空白には当たり判定いらないので あと入れ子のタグはそのまま
            $ret .= $_[$i]
        } elsif(!($f & 1)) {
            #id="1"とか安直なのは衝突あるかもなので避ける
            #古代のブラウザは_よめないかもしれんけどまあ無視
            $ret .= '<span id="_'."$cnt".'">'."$_[$i]".'</span>';
            $cnt += 1;
        }
    }
    return $ret;
}

