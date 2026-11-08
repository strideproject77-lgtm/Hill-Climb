package com.stride.compatgame;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.view.MotionEvent;
import android.view.View;

public final class MainActivity extends Activity {
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        setContentView(new GameView());
    }

    private static final class GameView extends View {
        private static final float W=960f, H=540f;
        private static final int MENU=0, RUNNING=1, OVER=2;
        private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Path path=new Path();
        private int state=MENU;
        private long lastFrame;
        private float distance, speed, fuel=100f, coins, wheelAngle;
        private float nextCoin=260f, nextFuel=1150f;
        private boolean gas, brake;

        GameView() { super(MainActivity.this); setLayerType(View.LAYER_TYPE_SOFTWARE,null); }

        private float ground(float x) {
            return 392f+(float)Math.sin(x*.0041f)*43f
                +(float)Math.sin(x*.0093f+1.1f)*17f
                +(float)Math.sin(x*.0017f+.4f)*49f;
        }

        @Override protected void onDraw(Canvas raw) {
            super.onDraw(raw);
            raw.save();
            raw.scale(getWidth()/W,getHeight()/H);
            long now=System.nanoTime();
            float dt=lastFrame==0?0f:Math.min(.04f,(now-lastFrame)/1_000_000_000f);
            lastFrame=now;
            if(state==RUNNING) update(dt);
            drawWorld(raw);
            raw.restore();
            postInvalidateOnAnimation();
        }

        private void update(float dt) {
            if(gas) speed+=190f*dt; else speed-=42f*dt;
            if(brake) speed-=260f*dt;
            speed=Math.max(0f,Math.min(330f,speed));
            distance+=speed*dt*.72f;
            wheelAngle+=speed*dt/22f;
            fuel-=(.55f+speed*.0024f)*dt;
            if(distance>=nextCoin) { coins++; nextCoin+=260f; }
            if(distance>=nextFuel) { fuel=Math.min(100f,fuel+28f); nextFuel+=1150f; }
            if(fuel<=0f) { fuel=0f; state=OVER; gas=false; brake=false; }
        }

        private void drawWorld(Canvas c) {
            p.setShader(new LinearGradient(0,0,0,H,
                new int[]{Color.rgb(105,177,213),Color.rgb(210,225,201)},null,Shader.TileMode.CLAMP));
            c.drawRect(0,0,W,H,p); p.setShader(null);
            p.setColor(Color.argb(55,255,255,255)); c.drawCircle(790,92,43,p);
            cloud(c,155,105); cloud(c,560,145);
            p.setColor(Color.rgb(111,159,135)); path.reset(); path.moveTo(0,320);
            for(int x=0;x<=980;x+=16) path.lineTo(x,285+(float)Math.sin((distance*.12f+x)*.004f)*35+(float)Math.sin(x*.012f)*15);
            path.lineTo(W,H); path.lineTo(0,H); path.close(); c.drawPath(path,p);
            path.reset(); path.moveTo(0,H);
            for(int x=0;x<=980;x+=5) path.lineTo(x,ground(distance+x));
            path.lineTo(W,H); path.close(); p.setColor(Color.rgb(105,76,51)); c.drawPath(path,p);
            path.reset();
            for(int x=0;x<=980;x+=5) { float y=ground(distance+x); if(x==0)path.moveTo(x,y);else path.lineTo(x,y); }
            p.setColor(Color.rgb(115,183,83)); p.setStyle(Paint.Style.STROKE); p.setStrokeWidth(13); p.setStrokeCap(Paint.Cap.ROUND); c.drawPath(path,p); p.setStyle(Paint.Style.FILL);
            collectible(c,nextCoin-distance,false); collectible(c,nextFuel-distance,true);
            car(c); hud(c);
            if(state==MENU) overlay(c,"POCKET RIDGE","A tiny off-road adventure","TAP TO START");
            if(state==OVER) overlay(c,"OUT OF FUEL","Distance: "+(int)distance+" m   •   Coins: "+(int)coins,"TAP TO DRIVE AGAIN");
        }

        private void cloud(Canvas c,float x,float y) {
            p.setColor(Color.argb(175,255,255,255));
            c.drawCircle(x,y,22,p); c.drawCircle(x+25,y-10,28,p); c.drawCircle(x+52,y,21,p);
            c.drawRoundRect(x-4,y-1,x+58,y+17,16,16,p);
        }

        private void collectible(Canvas c,float x,boolean can) {
            if(x < -30 || x > W+30)return;
            float y=ground(distance+x)-(can?65:74);
            if(can) {
                p.setColor(Color.rgb(230,157,51)); c.drawRoundRect(x-13,y-17,x+13,y+17,6,6,p);
                p.setColor(Color.WHITE); c.drawRect(x-5,y-10,x+5,y+10,p);
            } else {
                p.setColor(Color.rgb(255,204,48)); c.drawCircle(x,y,13,p);
                p.setColor(Color.rgb(255,239,143)); c.drawCircle(x-4,y-4,4,p);
            }
        }

        private void car(Canvas c) {
            float x=300f, road=ground(distance+x);
            float slope=(ground(distance+x+28)-ground(distance+x-28))/56f;
            c.save(); c.rotate((float)Math.toDegrees(Math.atan(slope)),x,road-23);
            p.setColor(Color.rgb(34,42,48)); c.drawRoundRect(x-43,road-28,x+43,road-4,9,9,p);
            p.setColor(Color.rgb(235,117,62)); c.drawRoundRect(x-39,road-49,x+38,road-17,11,11,p);
            p.setColor(Color.rgb(44,72,84)); c.drawRoundRect(x-12,road-45,x+22,road-27,6,6,p);
            wheel(c,x-27,road-7); wheel(c,x+27,road-7); c.restore();
        }

        private void wheel(Canvas c,float x,float y) {
            p.setColor(Color.rgb(25,29,31)); c.drawCircle(x,y,14,p);
            p.setColor(Color.rgb(177,187,188)); c.save(); c.rotate((float)Math.toDegrees(wheelAngle),x,y);
            c.drawRect(x-2,y-9,x+2,y+9,p); c.drawRect(x-9,y-2,x+9,y+2,p); c.restore();
        }

        private void hud(Canvas c) {
            p.setColor(Color.argb(180,17,31,38)); c.drawRoundRect(22,18,320,88,18,18,p);
            text(c,"DISTANCE  "+(int)distance+" m",42,48,20,Color.WHITE,true,false);
            text(c,"COINS  "+(int)coins,42,73,15,Color.rgb(255,218,92),true,false);
            p.setColor(Color.argb(180,17,31,38)); c.drawRoundRect(690,22,938,72,16,16,p);
            text(c,"FUEL",710,53,15,Color.WHITE,true,false);
            p.setColor(Color.rgb(55,65,66)); c.drawRoundRect(770,37,918,57,8,8,p);
            p.setColor(fuel>25?Color.rgb(114,207,99):Color.rgb(232,93,66));
            c.drawRoundRect(770,37,770+148*fuel/100f,57,8,8,p);
            button(c,54,424,174,510,"BRAKE",brake); button(c,732,424,174,510,"GAS",gas);
        }

        private void button(Canvas c,float x,float y,float w,float h,String label,boolean down) {
            p.setColor(down?Color.rgb(255,194,90):Color.argb(190,20,37,43));
            c.drawRoundRect(x,y,x+w,y+h,18,18,p);
            text(c,label,x+w/2,y+53,19,down?Color.rgb(49,45,34):Color.WHITE,true,true);
        }

        private void overlay(Canvas c,String title,String subtitle,String action) {
            p.setColor(Color.argb(165,12,25,31)); c.drawRoundRect(230,145,730,365,26,26,p);
            text(c,title,480,218,36,Color.WHITE,true,true);
            text(c,subtitle,480,258,17,Color.rgb(202,220,215),false,true);
            p.setColor(Color.rgb(164,219,103)); c.drawRoundRect(340,290,620,337,15,15,p);
            text(c,action,480,320,15,Color.rgb(30,48,35),true,true);
        }

        private void text(Canvas c,String s,float x,float y,float size,int color,boolean bold,boolean center) {
            p.setColor(color); p.setTextSize(size);
            p.setTypeface(Typeface.create("sans-serif",bold?Typeface.BOLD:Typeface.NORMAL));
            p.setTextAlign(center?Paint.Align.CENTER:Paint.Align.LEFT); c.drawText(s,x,y,p); p.setTextAlign(Paint.Align.LEFT);
        }

        @Override public boolean onTouchEvent(MotionEvent e) {
            float x=e.getX()*W/Math.max(1,getWidth()), y=e.getY()*H/Math.max(1,getHeight());
            switch(e.getActionMasked()) {
                case MotionEvent.ACTION_DOWN:
                case MotionEvent.ACTION_MOVE:
                    if(state!=RUNNING) {
                        state=RUNNING; distance=0; speed=0; fuel=100; coins=0;
                        nextCoin=260; nextFuel=1150; lastFrame=System.nanoTime();
                    } else {
                        brake=x<W*.42f && y>H*.72f;
                        gas=x>W*.58f && y>H*.72f;
                    }
                    invalidate(); return true;
                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_CANCEL:
                    gas=false; brake=false; performClick(); invalidate(); return true;
                default: return true;
            }
        }

        @Override public boolean performClick() { super.performClick(); return true; }
    }
}
