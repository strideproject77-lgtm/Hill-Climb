package com.stride.compatgame;

import android.app.Activity;
import android.os.Bundle;
import android.view.Gravity;
import android.view.MotionEvent;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * Pocket Calculator: iPhone-style dark calculator UI with a real arithmetic
 * state machine. It intentionally uses framework widgets and Activity touch
 * dispatch only, keeping the APK dependency-free for Stride compatibility tests.
 */
public final class MainActivity extends Activity {
    private TextView display;
    private String current = "0";
    private double stored = 0.0;
    private String pending = "";
    private boolean replaceInput = true;
    private boolean hasError = false;

    private static final String[][] KEYS = {
        {"AC", "+/-", "%", "÷"},
        {"7", "8", "9", "×"},
        {"4", "5", "6", "−"},
        {"1", "2", "3", "+"},
        {"0", ".", "⌫", "="}
    };

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        buildCalculator();
        updateDisplay();
    }

    private void buildCalculator() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(0xff000000);
        root.setPadding(12, 24, 12, 18);

        display = new TextView(this);
        display.setTextColor(0xffffffff);
        display.setTextSize(62.0f);
        display.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL);
        display.setPadding(8, 12, 12, 12);
        root.addView(display, new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 0, 1.0f));

        for (int row = 0; row < KEYS.length; row++) {
            LinearLayout line = new LinearLayout(this);
            line.setOrientation(LinearLayout.HORIZONTAL);
            for (int col = 0; col < KEYS[row].length; col++) {
                TextView key = new TextView(this);
                key.setText(KEYS[row][col]);
                key.setTextSize(27.0f);
                key.setGravity(Gravity.CENTER);
                key.setTextColor(0xffffffff);
                key.setBackgroundColor(keyColor(KEYS[row][col]));
                key.setPadding(4, 8, 4, 8);
                LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                    0, 0, KEYS[row][col].equals("0") ? 2.0f : 1.0f);
                lp.height = 0;
                lp.weight = KEYS[row][col].equals("0") ? 2.0f : 1.0f;
                lp.width = 0;
                lp.setMargins(5, 5, 5, 5);
                line.addView(key, lp);
            }
            LinearLayout.LayoutParams rowLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0, 1.0f);
            root.addView(line, rowLp);
        }
        setContentView(root);
    }

    private int keyColor(String key) {
        if (key.equals("÷") || key.equals("×") || key.equals("−") ||
            key.equals("+") || key.equals("=")) return 0xffff9f0a;
        if (key.equals("AC") || key.equals("+/-") || key.equals("%")) return 0xffa5a5a5;
        return 0xff333333;
    }

    @Override public boolean onTouchEvent(MotionEvent event) {
        if (event.getActionMasked() != MotionEvent.ACTION_DOWN) return true;
        float x = event.getX();
        float y = event.getY();
        float width = getWindow().getDecorView().getWidth();
        float height = getWindow().getDecorView().getHeight();
        if (width <= 0 || height <= 0) return true;

        // Display occupies the upper portion; the five key rows fill the rest.
        float keyAreaTop = height * 0.17f;
        if (y < keyAreaTop) return true;
        int row = (int)((y - keyAreaTop) / ((height - keyAreaTop) / 5.0f));
        int col = (int)(x / (width / 4.0f));
        if (row < 0) row = 0;
        if (row > 4) row = 4;
        if (col < 0) col = 0;
        if (col > 3) col = 3;
        String key;
        if (row == 4) {
            float segment = width / 5.0f;
            if (x < segment * 2.0f) key = "0";
            else if (x < segment * 3.0f) key = ".";
            else if (x < segment * 4.0f) key = "⌫";
            else key = "=";
        } else {
            key = KEYS[row][col];
        }
        press(key);
        return true;
    }

    private void press(String key) {
        if (key.equals("AC")) {
            current = "0"; stored = 0.0; pending = "";
            replaceInput = true; hasError = false;
        } else if (key.equals("+/-")) {
            if (!current.equals("0")) current = current.startsWith("-")
                ? current.substring(1) : "-" + current;
        } else if (key.equals("%")) {
            current = format(parse(current) / 100.0);
        } else if (key.equals("⌫")) {
            if (replaceInput || hasError) {
                current = "0"; hasError = false;
            } else if (current.length() <= 1 ||
                (current.length() == 2 && current.startsWith("-"))) {
                current = "0";
            } else {
                current = current.substring(0, current.length() - 1);
            }
        } else if (key.equals(".")) {
            if (replaceInput || hasError) {
                current = "0."; replaceInput = false; hasError = false;
            } else if (!current.contains(".")) current += ".";
        } else if (isOperator(key)) {
            stored = parse(current);
            pending = key;
            replaceInput = true;
        } else if (key.equals("=")) {
            if (!pending.equals("")) {
                double rhs = parse(current);
                double result = calculate(stored, rhs, pending);
                if (Double.isNaN(result) || Double.isInfinite(result)) {
                    current = "Error"; hasError = true;
                } else current = format(result);
                pending = ""; replaceInput = true;
            }
        } else {
            if (hasError || replaceInput || current.equals("0")) {
                current = key; replaceInput = false; hasError = false;
            } else if (current.length() < 14) current += key;
        }
        updateDisplay();
    }

    private boolean isOperator(String key) {
        return key.equals("+") || key.equals("−") ||
            key.equals("×") || key.equals("÷");
    }

    private double calculate(double a, double b, String op) {
        if (op.equals("+")) return a + b;
        if (op.equals("−")) return a - b;
        if (op.equals("×")) return a * b;
        if (op.equals("÷")) return b == 0.0 ? Double.NaN : a / b;
        return b;
    }

    private double parse(String value) {
        try { return Double.parseDouble(value); }
        catch (Exception ignored) { return 0.0; }
    }

    private String format(double value) {
        if (value == 0.0) return "0";
        if (Math.abs(value) < 1.0e12 && value == Math.rint(value))
            return String.valueOf((long)value);
        String result = String.valueOf(value);
        if (result.length() > 12) result = String.format(java.util.Locale.US, "%.8g", value);
        return result;
    }

    private void updateDisplay() {
        if (display != null) display.setText(current);
    }
}
