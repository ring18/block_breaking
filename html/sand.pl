#htmlのタグの中にspanタグを挟むスクリプト
#usage: cat fuga.html | nkf | perl sand.pl > edited.html
use warnings;
use strict;
use utf8;
use feature 'state';
use Encode;
binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";


my $inp = join "", <STDIN>;

#コメントウザいので抜く
#これやばいかもしれないのでちょっと考え直します
$inp =~ s/<!--.*?-->//sg;

#エンコードがらみの話 utf8へ
my $const_st1 = <<'EOS';
<style>
    #_main{
        position:fixed;
        width:100%;
        height:100%;
        z-index:20;
    }
    #_body {
        position:absolute;
        z-index: 10;
    }
</style>

EOS
my $const_st2 = <<'EOS';

<canvas id="_main"></canvas>
<section id = "_body">

EOS

my $const_st3 = <<'EOS';

<script  type="text/javascript">

    var canvas = document.getElementById("_main");
    var ctx = canvas.getContext("2d");
    var x;
    var y;//開始位置を中央下端に定義
    var dx=2;
    var dy=-2;//動いているように見せる
    var ballRadius = 8;
    var paddleHeight = 10;
    var paddleWidth = 75;
    var paddleX;
    var rightPressed = false;
    var leftPressed = false;

    document.addEventListener("keydown", keyDownHandler, false);
    document.addEventListener("keyup",keyUpHandler, false);
    document.addEventListener("mousemove", mouseMoveHandler,false);

    function mouseMoveHandler(e){
        var relativeX = e.clientX - canvas.offsetLeft;
        if(relativeX > 0 && relativeX < canvas.width){
            paddleX = relativeX - paddleWidth/2;
        }
    }
    function keyDownHandler(e){
        if(e.key == "Right" || e.key == "ArrowRight"){
            rightPressed = true;
        }
        else if(e.key =="Left" || e.key == "ArrowLeft"){
            leftPressed = true;
        }
    }

    function keyUpHandler(e){
        if(e.key == "Right" || e.key == "ArrowRight"){
            rightPressed = false;
        }
        else if (e.key == "Left" || e.key == "ArrowLeft"){
            leftPressed = false;
        }
    }
    //衝突検出span用
    function collisionDetection(){
        var sbrick=[];
        sbrick = document.elementsFromPoint(x,y);
        var c=0;
        while(sbrick[c]!=null){
            if(sbrick[c]=="[object HTMLSpanElement]"&&sbrick[c].id!="diminished"){
                sbrick[c].id = "diminished";
                sbrick[c].style.opacity=0;
                dy=-dy;
            }
            c++;
        }
    }


    window.onload = function() {
    function fitCanvasSize() {
  // Canvas のサイズをクライアントサイズに合わせる
      canvas.width = document.documentElement.clientWidth;
      canvas.height = document.documentElement.clientHeight;
      x = canvas.width/2;
      y = canvas.height-30;
      paddleX = (canvas.width-paddleWidth)/2;
      // Canvas 全体を塗りつぶし
      setInterval(draw,10);
     }
     fitCanvasSize();
    window.onresize = fitCanvasSize;
      }


      function drawball(){
          ctx.beginPath();
          ctx.arc(x,y,ballRadius,0,Math.PI*2);
          ctx.fillStyle = "#0095DD";
          ctx.globalCompositeOperation = 'source-over';
          ctx.fill();
          ctx.closePath();
      }

      function drawPaddle(){
          ctx.beginPath();
          ctx.rect(paddleX, canvas.height-paddleHeight,paddleWidth, paddleHeight);
          ctx.fillStyle = "#0095DD";
          ctx.globalCompositeOperation = 'source-over';
          ctx.fill();
          ctx.closePath();
      }

      function draw(){
          ctx.clearRect(0,0,canvas.width,canvas.height);
          drawball();
          drawPaddle();
          collisionDetection();
          if(x+dx>canvas.width-ballRadius || x+dx<ballRadius){
            dx=-dx;
        }

        if(y+dy<ballRadius){
            dy=-dy;
        }else if(y+dy > canvas.height-ballRadius){
            if(x>paddleX && x<paddleX+paddleWidth){
                dy=-dy;
            }
            else{
                alert("GAME OVER");
                x = canvas.width/2;
                  y = canvas.height-30;
                  dx=-dx;
                  dy=-dy;
            }
        }

        //パドル操作
        if(rightPressed && paddleX < canvas.width-paddleWidth){
            paddleX += 7;
        }
        else if(leftPressed && paddleX>0){
            paddleX-=7;
        } x += dx;
        y += dy;

      }
</script>
</section>

EOS
my $const_st4 = '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">';

$inp =~ s;</head>;$const_st1</head>;is;
$inp =~ s/(<meta(.*?) charset=)(.*?)>/$const_st4/is;
$inp =~ m;(.*?)<body(.*?)>(.*?)</body>(.*?);is;

my ($st1, $st2, $st3, $st4) = ($1, $2, $3, $4);

#body の中を探る
$st3 = &tag_sandwitcher($st3);
if ($st1 !~ /<!DOCTYPE/){
    $st1 = "<!DOCTYPE html>\n".$st1;
}

my $ret = "\n"."$st1"."<body"."$st2".">"."$st3"."</body>"."$st4"."\n</html>";

$ret =~ s/(<body(.*?)>)/$1$const_st2/is;
$ret =~ s;</body>;$const_st3</body>;is;
print "$ret"."\n";




#&tag_sandwitcher($st) ->$st の中を見て コンテンツをspanで挟むサブルーチン
#いじった$stを返す

sub tag_sandwitcher {
    state $cnt = 0;
    my $st = shift;
    my $ret;
    $st =~ s/<span(.*?)>/<_span$1>/sig;
    $st =~ s;</span(.*?)>;<_/span$1>;sig;
    $st =~ s/<script(.*?)>/<_script$1>/sig;
    $st =~ s;</script(.*?)>;<_/script$1>;sig;
    $st =~ s/<xmp(.*?)>/<_xmp$1>/sig;
    $st =~ s;</xmp(.*?)>;<_/xmp$1>;sig;
    @_ = split //,$st;
    #タグを飛ばすためのフラグ 1 -> <>のなか 2 -> &;のなか 4->scriptタグとかの中
    my $f = 0;
    for (my $i = 0; $i < length($st); $i++) {
        if($_[$i] =~ /[<>]/){
            #タグ発見
            $f ^= 1;
            if($_[$i] eq '<' and $_[$i + 1] eq '_'){
                $f ^= 4;
            }
            $ret .= $_[$i];
        } elsif (($_[$i] eq '&') and !($f & 1) and !($f & 4)){
            #特殊文字処理
            $ret .= '<span id="_'."$cnt".'">'.'&';
            $cnt += 1;
            $f ^= 2;
        } elsif (($f & 2) and !($f & 1) and !($f & 4)){
            #特殊文字処理
            if ($_[$i] eq ';') {
                $ret .= ';'.'</span>';
                $f ^= 2;
            } else {
                $ret .= $_[$i]
            }
        } elsif(($_[$i] =~ /\s/) or ($f & 1) or ($f & 4)){
            #空白には当たり判定いらないので 
            $ret .= $_[$i]
        } elsif(!($f & 1) ) {
            #id="1"とか安直なのは衝突あるかもなので避ける
            #古代のブラウザは_よめないかもしれんけどまあ無視
            $ret .= '<span id="_'."$cnt".'">'."$_[$i]".'</span>';
            $cnt += 1;
        }
    }
    $ret =~ s/<_(.*?)>/<$1>/sig;
    return $ret;
}


