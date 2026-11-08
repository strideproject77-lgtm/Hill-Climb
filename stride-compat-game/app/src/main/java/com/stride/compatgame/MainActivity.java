package com.stride.compatgame;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.view.MotionEvent;
import android.view.View;

/** Pocket Ridge Lite: one-Activity, one-DEX Canvas smoke-test game. */
public final class MainActivity extends Activity {
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        setContentView(new GameView());
    }

    private final class GameView extends View {
        private final Paint p = new Paint();
        private float playerX = 400f;
        private float obstacleX = 800f;
        private float obstacleY = 270f;
        private int score = 0;
        private boolean started = false;
        private boolean gameOver = false;

        GameView() {
            super(MainActivity.this);
            p.setAntiAlias(false);
            setFocusable(true);
        }

        private void rect(Canvas c, int color, float l, float t, float r, float b) {
            p.setColor(color);
            p.setStyle(Paint.Style.FILL);
            c.drawRect(l, t, r, b, p);
        }

        @Override protected void onDraw(Canvas c) {
            super.onDraw(c);
            float sx = getWidth() / 800f;
            float sy = getHeight() / 450f;
            c.save();
            c.scale(sx, sy);
            c.drawColor(Color.rgb(126, 190, 220));
            p.setColor(Color.rgb(255, 224, 117));
            c.drawCircle(690f, 70f, 28f, p);
            rect(c, Color.rgb(95, 155, 112), 0f, 320f, 800f, 450f);
            rect(c, Color.rgb(105, 76, 52), 0f, 345f, 800f, 450f);
            rect(c, Color.rgb(230, 111, 55), playerX - 24f, 290f, playerX + 24f, 338f);
            rect(c, Color.rgb(35, 40, 44), playerX - 19f, 333f, playerX - 7f, 345f);
            rect(c, Color.rgb(35, 40, 44), playerX + 7f, 333f, playerX + 19f, 345f);
            rect(c, Color.rgb(55, 70, 78), obstacleX, obstacleY, obstacleX + 28f, 345f);
            rect(c, Color.rgb(25, 42, 48), 18f, 18f, 150f, 62f);
            for (int i = 0; i < score && i < 8; i++) {
                p.setColor(Color.rgb(255, 204, 48));
                c.drawCircle(35f + i * 14f, 40f, 4f, p);
            }
            if (!started || gameOver) {
                rect(c, Color.rgb(28, 43, 50), 250f, 155f, 550f, 285f);
                rect(c, Color.rgb(162, 218, 104), 315f, 235f, 485f, 265f);
                p.setColor(Color.WHITE);
                c.drawCircle(400f, 205f, 18f, p);
            }
            c.restore();

            if (started && !gameOver) {
                obstacleX -= 5f;
                if (obstacleX < -30f) {
                    obstacleX = 820f;
                    obstacleY = 250f + (score % 3) * 20f;
                    score++;
                }
                if (obstacleX < playerX + 18f && obstacleX + 28f > playerX - 18f
                        && obstacleY < 338f) {
                    gameOver = true;
                }
                postInvalidateDelayed(16L);
            }
        }

        @Override public boolean onTouchEvent(MotionEvent e) {
            int action = e.getActionMasked();
            if (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_MOVE) {
                float x = e.getX() * 800f / Math.max(1, getWidth());
                if (!started || gameOver) {
                    started = true;
                    gameOver = false;
                    score = 0;
                    obstacleX = 820f;
                } else {
                    playerX = Math.max(45f, Math.min(755f, x));
                }
                invalidate();
                return true;
            }
            return true;
        }
    }
}
