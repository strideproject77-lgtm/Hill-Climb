package com.stride.compatgame;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.view.MotionEvent;
import android.view.View;

/**
 * Pocket Ridge: a deliberately small Java/Canvas compatibility game.
 * Rendering is limited to Canvas color/scale/rect/circle/line/path primitives.
 */
public final class MainActivity extends Activity {
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        setContentView(new RidgeView());
    }

    private final class RidgeView extends View {
        private static final float WORLD_W = 800f;
        private static final float WORLD_H = 450f;
        private static final int MENU = 0;
        private static final int PLAYING = 1;
        private static final int FINISHED = 2;

        private final Paint paint = new Paint();
        private final Path terrain = new Path();
        private int mode = MENU;
        private float travel;
        private float speed;
        private float fuel = 100f;
        private int coins;
        private boolean gas;
        private boolean brake;
        private int frame;

        RidgeView() {
            super(MainActivity.this);
            paint.setAntiAlias(false);
        }

        private float clamp(float value, float low, float high) {
            if (value < low) return low;
            if (value > high) return high;
            return value;
        }

        // Triangle-wave hills avoid trigonometric/native-library dependencies.
        private float ground(float worldX) {
            float a = worldX % 320f;
            if (a < 0f) a += 320f;
            float first = a < 160f ? a / 160f : (320f - a) / 160f;
            float b = (worldX + 91f) % 470f;
            if (b < 0f) b += 470f;
            float second = b < 235f ? b / 235f : (470f - b) / 235f;
            return 330f - first * 62f - second * 24f;
        }

        private void color(int value) {
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(value);
        }

        @Override protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            float sx = getWidth() / WORLD_W;
            float sy = getHeight() / WORLD_H;
            canvas.save();
            canvas.scale(sx, sy);

            if (mode == PLAYING) stepGame();

            canvas.drawColor(Color.rgb(125, 190, 220));
            drawSun(canvas);
            drawDistantHills(canvas);
            drawGround(canvas);
            drawPickups(canvas);
            drawVehicle(canvas);
            drawControls(canvas);
            drawStatus(canvas);

            if (mode == MENU) drawOverlay(canvas, 0);
            if (mode == FINISHED) drawOverlay(canvas, 1);

            canvas.restore();
            invalidate();
        }

        private void stepGame() {
            frame++;
            if (gas) speed += 0.9f;
            else speed -= 0.22f;
            if (brake) speed -= 1.35f;
            speed = clamp(speed, 0f, 9f);
            travel += speed;
            fuel -= 0.012f + speed * 0.0009f;
            if (frame % 80 == 0 && speed > 1f) coins++;
            if (fuel <= 0f) {
                fuel = 0f;
                mode = FINISHED;
                gas = false;
                brake = false;
            }
        }

        private void drawSun(Canvas c) {
            color(Color.rgb(255, 224, 117));
            c.drawCircle(690f, 75f, 31f, paint);
        }

        private void drawDistantHills(Canvas c) {
            color(Color.rgb(104, 157, 130));
            terrain.reset();
            terrain.moveTo(0f, WORLD_H);
            for (int x = 0; x <= 800; x += 20) {
                float y = 260f + ground(travel * 0.25f + x) * 0.18f;
                terrain.lineTo(x, y);
            }
            terrain.lineTo(WORLD_W, WORLD_H);
            terrain.close();
            c.drawPath(terrain, paint);
        }

        private void drawGround(Canvas c) {
            color(Color.rgb(115, 79, 51));
            terrain.reset();
            terrain.moveTo(0f, WORLD_H);
            for (int x = 0; x <= 800; x += 8) {
                terrain.lineTo(x, ground(travel + x));
            }
            terrain.lineTo(WORLD_W, WORLD_H);
            terrain.close();
            c.drawPath(terrain, paint);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(7f);
            paint.setColor(Color.rgb(111, 183, 79));
            terrain.reset();
            for (int x = 0; x <= 800; x += 8) {
                float y = ground(travel + x);
                if (x == 0) terrain.moveTo(x, y);
                else terrain.lineTo(x, y);
            }
            c.drawPath(terrain, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawPickups(Canvas c) {
            // Repeating pickups are visual-only score markers in this first slice.
            for (int i = 0; i < 5; i++) {
                float world = ((int)(travel / 360f) * 360f) + 210f + i * 360f;
                float x = world - travel + 300f;
                if (x < 12f || x > 788f) continue;
                float y = ground(world) - 34f;
                color(Color.rgb(255, 204, 48));
                c.drawCircle(x, y, 10f, paint);
                color(Color.rgb(255, 245, 190));
                c.drawCircle(x - 3f, y - 3f, 3f, paint);
            }
        }

        private void drawVehicle(Canvas c) {
            float x = 300f;
            float y = ground(travel + x);
            color(Color.rgb(231, 111, 55));
            c.drawRect(x - 38f, y - 42f, x + 38f, y - 13f, paint);
            color(Color.rgb(49, 75, 83));
            c.drawRect(x - 8f, y - 38f, x + 20f, y - 19f, paint);
            color(Color.rgb(27, 30, 32));
            c.drawCircle(x - 24f, y - 8f, 12f, paint);
            c.drawCircle(x + 25f, y - 8f, 12f, paint);
            color(Color.rgb(180, 190, 190));
            c.drawCircle(x - 24f, y - 8f, 5f, paint);
            c.drawCircle(x + 25f, y - 8f, 5f, paint);
        }

        private void drawControls(Canvas c) {
            color(Color.rgb(38, 53, 58));
            c.drawRect(28f, 366f, 205f, 432f, paint);
            c.drawRect(595f, 366f, 772f, 432f, paint);
            color(Color.rgb(245, 245, 230));
            c.drawLine(78f, 399f, 155f, 399f, paint);
            c.drawLine(116f, 380f, 116f, 418f, paint);
            c.drawLine(650f, 399f, 718f, 399f, paint);
            c.drawLine(684f, 380f, 684f, 418f, paint);
        }

        private void drawStatus(Canvas c) {
            color(Color.rgb(27, 43, 48));
            c.drawRect(18f, 16f, 270f, 74f, paint);
            color(Color.rgb(255, 255, 255));
            c.drawRect(34f, 34f, 240f, 43f, paint);
            color(Color.rgb(102, 202, 91));
            c.drawRect(34f, 34f, 34f + 206f * fuel / 100f, 43f, paint);
            // Score is represented by coin markers; no text/font API is required.
            for (int i = 0; i < coins && i < 8; i++) {
                color(Color.rgb(255, 204, 48));
                c.drawCircle(40f + i * 22f, 59f, 5f, paint);
            }
        }

        private void drawOverlay(Canvas c, int finished) {
            color(Color.rgb(29, 45, 50));
            c.drawRect(215f, 145f, 585f, 300f, paint);
            color(Color.rgb(162, 218, 104));
            c.drawRect(270f, 245f, 530f, 278f, paint);
            // A different center marker indicates start vs restart without text rendering.
            color(finished == 0 ? Color.rgb(54, 104, 66) : Color.rgb(128, 75, 43));
            c.drawCircle(400f, 211f, 27f, paint);
            color(Color.WHITE);
            c.drawRect(393f, 198f, 407f, 224f, paint);
        }

        private void startNewRun() {
            mode = PLAYING;
            travel = 0f;
            speed = 0f;
            fuel = 100f;
            coins = 0;
            frame = 0;
            gas = false;
            brake = false;
        }

        @Override public boolean onTouchEvent(MotionEvent event) {
            float x = event.getX() * WORLD_W / Math.max(1, getWidth());
            float y = event.getY() * WORLD_H / Math.max(1, getHeight());
            int action = event.getActionMasked();

            if (mode != PLAYING) {
                if (action == MotionEvent.ACTION_DOWN) {
                    startNewRun();
                    invalidate();
                }
                return true;
            }

            if (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_MOVE) {
                gas = x > 560f && y > 350f;
                brake = x < 240f && y > 350f;
                invalidate();
                return true;
            }
            if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_CANCEL) {
                gas = false;
                brake = false;
                invalidate();
                return true;
            }
            return true;
        }
    }
}
