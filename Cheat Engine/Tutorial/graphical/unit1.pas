unit Unit1;

{$mode objfpc}{$H+}

interface

//tutorial step1: player and target, 1 single bullet at a time.
//the player has an ammo capacity of  5 bullets, and the target heals itself each time the player reloads
//each bullet does 10 damage, and the target has 100 health...

//the task: destroy the target.  (e.g add more bullets, make the bullets do more damage, change to code to instant kill, jump to the success code, ...)

uses
  windows, Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  GamePanel, renderobject,glext, GL,glu, player,scoreboard, target, bullet, guitextobject;

type



  { TForm1 }
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    player: TPlayer;

    target: Ttarget;
    bullets: array[0..4] of Tbullet; //max 5 bullets on the screen at once

   // scoreboard: Tscoreboard;

    lasttick: qword;

    reloading: qword;
    shotsfired: integer;

    lastshot: qword;

    rotatedirection: single;

    status: TGUITextObject;

    procedure renderGame(sender: TObject);
    procedure gametick(sender: TObject);
    function KeyHandler(TGamePanel: TObject; keventtype: integer; Key: Word; Shift: TShiftState):boolean;
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }


procedure TForm1.FormCreate(Sender: TObject);
begin

end;

procedure TForm1.gametick(sender:TObject);
var
  currenttime: qword;
  diff: qword;
  i: integer;
begin
  //do game mechanics like movements and AI
  //rotate the enemy to the player
  //enemy.rotation:=enemy.rotation+0.5;

  currenttime:=GetTickCount64;
  diff:=currenttime-lasttick;
  lasttick:=currenttime;

  if reloading<>0 then
  begin
    //check if done reloading
    if currenttime>(reloading+2000) then
    begin
      status.text:=format('Ammo till reload:'#13#10'%d',[5]);
      reloading:=0;
    end;
  end;






  if player<>nil then
  begin
    player.rotation:=player.rotation+rotatedirection*diff;
  end;

  for i:=0 to 4 do
    if bullets[i]<>nil then
    begin
      bullets[i].travel(diff);

      if (target<>nil) and bullets[i].checkCollision(target) then //perhaps use a vector based on old x,y and new x,y
      begin
        target.health:=target.health-10;
        if target.health<=0 then
        begin
          freeandnil(target);
        end;

        freeandnil(bullets[i]);
      end;

      if (bullets[i]<>nil) and ((bullets[i].x>1) or (bullets[i].y>1) or (bullets[i].x<-1) or (bullets[i].y<-1)) then
      begin
        freeandnil(bullets[i]);
        exit;
      end;
    end;
end;

procedure TForm1.renderGame(sender: TObject);
var i: integer;
begin
  player.render;
  if target<>nil then
    target.render;

  for i:=0 to 4 do
    if bullets[i]<>nil then
      bullets[i].render;

  status.render;
end;

function TForm1.KeyHandler(TGamePanel: TObject; keventtype: integer; Key: Word; Shift: TShiftState):boolean;
var
  x: boolean;
  i: integer;
  ct: qword;
begin
  if keventtype=0 then
  begin
    ct:=GetTickCount64;

    if key=vk_space then
    begin
      if reloading<>0 then exit;

      if ct<lastshot+100 then exit; //rate limit the amount of bullets

      x:=false;
      for i:=0 to 4 do
        if bullets[i]=nil then
        begin
          //create a bullet
          bullets[i]:=tbullet.create;
          bullets[i].x:=player.x;
          bullets[i].y:=player.y;
          bullets[i].rotation:=player.rotation;
          x:=true;
          inc(shotsfired);
          lastshot:=ct;

          status.text:=format('Ammo till reload:'#13#10'%d',[5-shotsfired]);

          if shotsfired=5 then  //this ends up being extremely shitty giving the player hope he can win by timning it right. (not gonna happen lol)
          begin

            reloading:=ct;
            if target<>nil then target.health:=100;
            //create a reloading progressbar

            status.text:='<RELOADING>';
            shotsfired:=0;
           // showmessage('reloading');
          end;
          break;
        end;


    end
    else
    begin
      case key of
        VK_LEFT,VK_A: if RotateDirection>=0 then rotatedirection:=-0.1;
        VK_RIGHT,VK_D: if RotateDirection<=0 then rotatedirection:=+0.1;
      end;
    end;
  end
  else
  begin
    case key of
      VK_LEFT,VK_A: if RotateDirection<0 then rotatedirection:=0;
      VK_RIGHT,VK_D: if RotateDirection>0 then rotatedirection:=0;
    end;
  end;
  result:=false;
end;

procedure TForm1.FormShow(Sender: TObject);
var p: TGamePanel;
begin
  p:=TGamePanel.Create(Self);
  p.OnGameRender:=@renderGame;
  p.OnGameTick:=@gametick;
  p.Align:=alClient;
  p.parent:=self;

  player:=tplayer.create;
  player.x:=0;
  player.y:=0.8;

  target:=TTarget.create;
  target.x:=0;
  target.y:=-0.8;
  target.health:=100;

  //create a gui
  {
  scoreboard:=TScoreBoard.create(p);
  scoreboard.x:=-1;
  scoreboard.y:=-1;
  }

  status:=TGUITextObject.create;
  status.firstTextBecomesMinWidth:=true;
  status.font.Size:=78;

  status.width:=0.4;
  status.height:=0.3;
  status.x:=1-status.width;
  status.y:=1-status.height;

  status.textalignment:=taCenter;
  status.firstTextBecomesMinWidth:=true;
  status.color:=clred;
  status.bcolor:=clgreen;

  status.text:='Ammo till reload:'#13#10'5';



  lasttick:=GetTickCount64;

  p.AddKeyEventHandler(@keyhandler);


end;

end.

