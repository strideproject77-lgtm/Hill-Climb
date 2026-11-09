package com.stride.compatgame;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import android.view.MotionEvent;

/**
 * Tap Trail: a deliberately small Android game for Stride's currently
 * implemented Activity, MotionEvent and TextView framework surface.
 * It avoids custom View drawing, Canvas, native libraries and third-party APIs.
 */
public final class MainActivity extends Activity {
    private TextView screen;
    private int steps;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        steps = 0;
        screen = new TextView(this);
        screen.setTextSize(26.0f);
        screen.setTextColor(0xffffffff);
        screen.setBackgroundColor(0xff1e2b36);
        screen.setText("TAP TRAIL\n\nTap anywhere to start\n\nReach the summit in 5 taps!");
        setContentView(screen);
    }

    @Override public boolean onTouchEvent(MotionEvent event) {
        if (event.getActionMasked() != MotionEvent.ACTION_DOWN) {
            return true;
        }

        if (steps == 0) {
            steps = 1;
            screen.setText("TAP TRAIL\n\nTrail started!\n\n1 / 5 steps\n\nKeep tapping");
        } else if (steps == 1) {
            steps = 2;
            screen.setText("TAP TRAIL\n\nNice pace!\n\n2 / 5 steps\n\nKeep going");
        } else if (steps == 2) {
            steps = 3;
            screen.setText("TAP TRAIL\n\nHalfway there!\n\n3 / 5 steps\n\nOne more push");
        } else if (steps == 3) {
            steps = 4;
            screen.setText("TAP TRAIL\n\nAlmost at the top!\n\n4 / 5 steps\n\nFinal tap");
        } else if (steps == 4) {
            steps = 5;
            screen.setText("TAP TRAIL\n\nSUMMIT REACHED!\n\n5 / 5 steps\n\nTap to play again");
        } else {
            steps = 0;
            screen.setText("TAP TRAIL\n\nNew trail!\n\nTap to start\n\nReach the summit in 5 taps!");
        }
        return true;
    }
}
