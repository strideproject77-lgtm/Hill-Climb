package com.stride.compatgame;

import android.app.Activity;
import android.os.Bundle;
import android.view.MotionEvent;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * Pocket Calculator compatibility APK.
 * Uses the managed Android View tree so Stride can rasterize it into the guest
 * Surface. Input is handled by Activity.onTouchEvent using guest coordinates.
 */
public final class MainActivity extends Activity {
    private static final int BLACK = 0xff000000;
    private static final int WHITE = 0xffffffff;
    private static final int ORANGE = 0xffff9f0a;
    private static final int LIGHT = 0xffa5a5a5;
    private static final int DARK = 0xff333333;

    private String current = "0";
    private double stored = 0.0;
    private String pending = "";
    private boolean replaceInput = true;
    private boolean error = false;
    private TextView display;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        buildViewTree();
    }

    private void buildViewTree() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(BLACK);

        display = new TextView(this);
        display.setText(current);
        display.setTextColor(WHITE);
        display.setTextSize(42.0f);
        display.setBackgroundColor(BLACK);
        root.addView(display);

        for (int row = 0; row < 5; row++) {
            LinearLayout keyRow = new LinearLayout(this);
            keyRow.setOrientation(LinearLayout.HORIZONTAL);
            for (int col = 0; col < 4; col++) {
                TextView key = new TextView(this);
                key.setText(keyAt(row, col));
                key.setTextSize(24.0f);
                key.setTextColor(row == 0 && col < 3 ? BLACK : WHITE);
                key.setBackgroundColor(row == 0 && col < 3 ? LIGHT : (col == 3 ? ORANGE : DARK));
                keyRow.addView(key);
            }
            root.addView(keyRow);
        }
        setContentView(root);
    }

    /** Returns the real calculator key label without a static multidimensional array. */
    private String keyAt(int row, int col) {
        if (row == 0) {
            if (col == 0) return "AC";
            if (col == 1) return "+/-";
            if (col == 2) return "%";
            return "÷";
        }
        if (row == 1) {
            if (col == 0) return "7";
            if (col == 1) return "8";
            if (col == 2) return "9";
            return "×";
        }
        if (row == 2) {
            if (col == 0) return "4";
            if (col == 1) return "5";
            if (col == 2) return "6";
            return "−";
        }
        if (row == 3) {
            if (col == 0) return "1";
            if (col == 1) return "2";
            if (col == 2) return "3";
            return "+";
        }
        if (col == 0) return "0";
        if (col == 1) return ".";
        if (col == 2) return "⌫";
        return "=";
    }

    @Override public boolean onTouchEvent(MotionEvent event) {
        if (event.getActionMasked() != MotionEvent.ACTION_DOWN) return true;
        // The guest Surface is 1080x1920. MotionEvent coordinates are already
        // translated into guest-surface coordinates by Stride's input bridge.
        float x = event.getX();
        float y = event.getY();
        int col = Math.max(0, Math.min(3, (int)(x / 270.0f)));
        int row = (int)(y / 320.0f) - 1;
        if (row < 0) return true;
        if (row > 4) row = 4;
        press(keyAt(row, col));
        if (display != null) display.setText(current);
        return true;
    }

    private void press(String key) {
        if (key.equals("AC")) {
            current = "0"; stored = 0.0; pending = "";
            replaceInput = true; error = false;
        } else if (key.equals("+/-")) {
            if (!current.equals("0") && !error)
                current = current.startsWith("-") ? current.substring(1) : "-".concat(current);
        } else if (key.equals("%")) {
            current = format(parse(current) / 100.0);
        } else if (key.equals("⌫")) {
            if (replaceInput || error) { current = "0"; error = false; }
            else if (current.length() <= 1 || (current.length() == 2 && current.startsWith("-"))) current = "0";
            else current = current.substring(0, current.length() - 1);
        } else if (key.equals(".")) {
            if (replaceInput || error) { current = "0."; replaceInput = false; error = false; }
            else if (!current.contains(".")) current = current.concat(".");
        } else if (isOperator(key)) {
            stored = parse(current); pending = key; replaceInput = true;
        } else if (key.equals("=")) {
            if (!pending.equals("")) {
                double result = calculate(stored, parse(current), pending);
                if (result != result || result > Double.MAX_VALUE || result < -Double.MAX_VALUE) {
                    current = "Error"; error = true;
                } else current = format(result);
                pending = ""; replaceInput = true;
            }
        } else {
            if (replaceInput || error || current.equals("0")) {
                current = key; replaceInput = false; error = false;
            } else if (current.length() < 14) current = current.concat(key);
        }
    }

    private boolean isOperator(String key) {
        return key.equals("+") || key.equals("−") || key.equals("×") || key.equals("÷");
    }
    private double calculate(double a, double b, String op) {
        if (op.equals("+")) return a + b;
        if (op.equals("−")) return a - b;
        if (op.equals("×")) return a * b;
        if (op.equals("÷")) return b == 0.0 ? Double.NaN : a / b;
        return b;
    }
    private double parse(String value) {
        try { return Double.parseDouble(value); } catch (Exception ignored) { return 0.0; }
    }
    private String format(double value) {
        if (value == 0.0) return "0";
        return String.valueOf(value);
    }
}
