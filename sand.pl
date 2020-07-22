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
$inp =~ s/<!--.*?-->//sg;

#エンコードがらみの話 utf8へ
my $const_st1 = <<'EOS';
<style>
    #main{
        position:fixed;
        width:100%;
        height:100%;
        z-index:20;
    }
    #body {
        position:absolute;
        z-index: 10;
    }
</style>

EOS
my $const_st2 = <<'EOS';

<canvas id="main"></canvas>
<section id = "body">

EOS

my $const_st3 = <<'EOS';

<script  type="text/javascript">

    var canvas = document.getElementById("main");
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

$inp =~ s;</head>;$const_st1</head>;s;
$inp =~ s/(<meta(.*?) charset=)(.*?)>/$1UTF-8>/s;
$inp =~ m;(.*?)<body(.*?)>(.*?)</body>(.*?);s;

my ($st1, $st2, $st3, $st4) = ($1, $2, $3, $4);

#body の中を探る
$st3 = &tag_sandwitcher($st3);
if ($st1 !~ /<!DOCTYPE/){
    $st1 = "<!DOCTYPE html>\n".$st1;
}

my $ret = "$st1"."<body"."$st2".">"."$st3"."</body>"."$st4"."\n</html>";

$ret =~ s/(<body(.*?)>)/$1$const_st2/s;
$ret =~ s;</body>;$const_st3</body>;s;
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

