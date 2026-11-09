package com.stride.compatgame;

import android.app.Activity;
import android.os.Bundle;
import android.view.MotionEvent;
import android.widget.TextView;

/**
 * Tap Blink: a tiny Stride compatibility app using only Activity,
 * MotionEvent and TextView APIs. No Canvas, custom View or native code.
 */
public final class MainActivity extends Activity {
    private TextView screen;
    private boolean bright;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        bright = false;
        screen = new TextView(this);
        screen.setTextSize(28.0f);
        screen.setTextColor(0xffffffff);
        screen.setBackgroundColor(0xff101820);
        screen.setText("TAP BLINK\n\nTap anywhere!\n\nEach tap makes the screen blink.");
        setContentView(screen);
    }

    @Override public boolean onTouchEvent(MotionEvent event) {
        if (event.getActionMasked() != MotionEvent.ACTION_DOWN) {
            return true;
        }

        bright = !bright;
        if (bright) {
            screen.setBackgroundColor(0xff35c9ff);
            screen.setTextColor(0xff101820);
            screen.setText("✦ BLINK! ✦\n\nTap detected\nX: " + (int) event.getX()
                + "   Y: " + (int) event.getY() + "\n\nTap again to blink");
        } else {
            screen.setBackgroundColor(0xff101820);
            screen.setTextColor(0xffffffff);
            screen.setText("TAP BLINK\n\nBlink!\nX: " + (int) event.getX()
                + "   Y: " + (int) event.getY() + "\n\nTap anywhere");
        }
        return true;
    }
}
