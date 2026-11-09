package com.stride.compatgame;

import android.app.Activity;
import android.os.Bundle;
import android.view.MotionEvent;
import android.widget.TextView;

/**
 * Tap Blink: a minimal touch-response app using only bridged Android APIs.
 * Each touch visibly toggles the screen; no demo content or fake game state.
 */
public final class MainActivity extends Activity {
    private TextView screen;
    private boolean blinkOn;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        blinkOn = false;
        screen = new TextView(this);
        screen.setTextSize(28.0f);
        screen.setTextColor(0xffffffff);
        screen.setBackgroundColor(0xff101820);
        screen.setText("TAP BLINK\n\nTouch anywhere to blink");
        setContentView(screen);
    }

    @Override public boolean onTouchEvent(MotionEvent event) {
        if (event.getActionMasked() != MotionEvent.ACTION_DOWN) {
            return true;
        }

        blinkOn = !blinkOn;
        if (blinkOn) {
            screen.setBackgroundColor(0xff35c9ff);
            screen.setTextColor(0xff101820);
            screen.setText("BLINK!");
        } else {
            screen.setBackgroundColor(0xff101820);
            screen.setTextColor(0xffffffff);
            screen.setText("TAP BLINK\n\nTouch anywhere");
        }
        return true;
    }
}
