package com.stride.compatgame;

import android.app.Activity;
import android.os.Bundle;
import android.view.MotionEvent;

/**
 * Minimal iPhone-style calculator for Stride compatibility testing.
 * Uses only Activity, Bundle and MotionEvent APIs already exercised by Tap Blink.
 * Drawing and hit testing are performed by the Activity itself; no widget tree.
 */
public final class MainActivity extends Activity {
    private static final String[][] KEYS = {
        {"AC", "+/-", "%", "÷"},
        {"7", "8", "9", "×"},
        {"4", "5", "6", "−"},
        {"1", "2", "3", "+"},
        {"0", ".", "⌫", "="}
    };
    private static final int WHITE = 0xffffffff;
    private static final int BLACK = 0xff000000;
    private static final int ORANGE = 0xffff9f0a;
    private static final int LIGHT = 0xffa5a5a5;
    private static final int DARK = 0xff333333;

    private String current = "0";
    private double stored = 0.0;
    private String pending = "";
    private boolean replaceInput = true;
    private boolean error = false;
    private int[] pixels;
    private int surfaceWidth;
    private int surfaceHeight;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        render();
    }

    @Override public boolean onTouchEvent(MotionEvent event) {
        if (event.getActionMasked() != MotionEvent.ACTION_DOWN) return true;
        float x = event.getX();
        float y = event.getY();
        int width = getWindow().getDecorView().getWidth();
        int height = getWindow().getDecorView().getHeight();
        if (width <= 0 || height <= 0) return true;
        float top = height * 0.25f;
        if (y < top) return true;
        int row = (int)((y - top) / ((height - top) / 5.0f));
        int col = (int)(x / (width / 4.0f));
        if (row < 0) row = 0;
        if (row > 4) row = 4;
        if (col < 0) col = 0;
        if (col > 3) col = 3;
        String key = KEYS[row][col];
        if (row == 4) {
            float segment = width / 5.0f;
            if (x < segment * 2.0f) key = "0";
            else if (x < segment * 3.0f) key = ".";
            else if (x < segment * 4.0f) key = "⌫";
            else key = "=";
        }
        press(key);
        render();
        return true;
    }

    private void press(String key) {
        if (key.equals("AC")) {
            current = "0"; stored = 0.0; pending = "";
            replaceInput = true; error = false;
        } else if (key.equals("+/-")) {
            if (!current.equals("0") && !error)
                current = current.startsWith("-") ? current.substring(1) : "-" + current;
        } else if (key.equals("%")) {
            current = format(parse(current) / 100.0);
        } else if (key.equals("⌫")) {
            if (replaceInput || error) { current = "0"; error = false; }
            else if (current.length() <= 1 || (current.length() == 2 && current.startsWith("-"))) current = "0";
            else current = current.substring(0, current.length() - 1);
        } else if (key.equals(".")) {
            if (replaceInput || error) { current = "0."; replaceInput = false; error = false; }
            else if (!current.contains(".")) current += ".";
        } else if (isOperator(key)) {
            stored = parse(current); pending = key; replaceInput = true;
        } else if (key.equals("=")) {
            if (!pending.equals("")) {
                double result = calculate(stored, parse(current), pending);
                if (Double.isNaN(result) || Double.isInfinite(result)) {
                    current = "Error"; error = true;
                } else current = format(result);
                pending = ""; replaceInput = true;
            }
        } else {
            if (replaceInput || error || current.equals("0")) {
                current = key; replaceInput = false; error = false;
            } else if (current.length() < 14) current += key;
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
        if (Math.abs(value) < 1.0e12 && value == Math.rint(value)) return String.valueOf((long)value);
        String result = String.valueOf(value);
        if (result.length() > 12) result = String.format(java.util.Locale.US, "%.8g", value);
        return result;
    }

    // Software raster output: black canvas, large right-aligned value and round keys.
    // Pixel text uses a compact built-in 5x7 glyph table, avoiding Android TextView.
    private void render() {
        int width = getWindow().getDecorView().getWidth();
        int height = getWindow().getDecorView().getHeight();
        if (width <= 0 || height <= 0) { width = 390; height = 844; }
        surfaceWidth = width; surfaceHeight = height;
        pixels = new int[width * height];
        for (int i = 0; i < pixels.length; i++) pixels[i] = BLACK;
        int top = (int)(height * 0.25f);
        drawText(current, width - 28 - current.length() * Math.max(12, width / 23),
            top - height / 12, WHITE, Math.max(12, width / 23));
        int keyTop = top;
        int rowHeight = (height - keyTop) / 5;
        for (int row = 0; row < 5; row++) {
            for (int col = 0; col < 4; col++) {
                int left = col * width / 4 + 5;
                int right = (col + 1) * width / 4 - 5;
                int cy = keyTop + row * rowHeight + rowHeight / 2;
                int radius = Math.min((right-left)/2, rowHeight/2) - 3;
                int color = row == 0 && col < 3 ? LIGHT :
                    (col == 3 ? ORANGE : DARK);
                if (row == 4 && col == 0) {
                    left = 5; right = width * 2 / 5 - 5;
                }
                fillCircle((left+right)/2, cy, radius, color);
                String label = KEYS[row][col];
                if (row == 4) label = col == 0 ? "0" : col == 1 ? "." : col == 2 ? "⌫" : "=";
                int scale = Math.max(2, width / 195);
                int tw = label.length() * 6 * scale;
                drawText(label, (left+right-tw)/2, cy-3*scale, row == 0 && col < 3 ? BLACK : WHITE, scale);
            }
        }
        // Keep the frame buffer available to the host's supported surface path.
        // Activity content view is deliberately not created through unsupported widgets.
    }

    private void fillCircle(int cx, int cy, int radius, int color) {
        int y0 = Math.max(0, cy-radius), y1 = Math.min(surfaceHeight-1, cy+radius);
        for (int y=y0; y<=y1; y++) {
            int dx = (int)Math.sqrt(radius*radius-(y-cy)*(y-cy));
            int x0=Math.max(0,cx-dx), x1=Math.min(surfaceWidth-1,cx+dx);
            for(int x=x0;x<=x1;x++) pixels[y*surfaceWidth+x]=color;
        }
    }
    private void drawText(String text, int x, int y, int color, int scale) {
        for(int i=0;i<text.length();i++) {
            int[] glyph=glyph(text.charAt(i));
            for(int gy=0;gy<7;gy++) for(int gx=0;gx<5;gx++) {
                if((glyph[gy]&(1<<(4-gx)))!=0) {
                    for(int sy=0;sy<scale;sy++) for(int sx=0;sx<scale;sx++) {
                        int px=x+i*6*scale+gx*scale+sx, py=y+gy*scale+sy;
                        if(px>=0&&px<surfaceWidth&&py>=0&&py<surfaceHeight)
                            pixels[py*surfaceWidth+px]=color;
                    }
                }
            }
        }
    }
    private int[] glyph(char c) {
        switch(c) {
            case '0': return new int[]{14,17,19,21,25,17,14};
            case '1': return new int[]{4,12,4,4,4,4,14};
            case '2': return new int[]{14,17,1,2,4,8,31};
            case '3': return new int[]{30,1,1,14,1,1,30};
            case '4': return new int[]{2,6,10,18,31,2,2};
            case '5': return new int[]{31,16,16,30,1,1,30};
            case '6': return new int[]{14,16,16,30,17,17,14};
            case '7': return new int[]{31,1,2,4,8,8,8};
            case '8': return new int[]{14,17,17,14,17,17,14};
            case '9': return new int[]{14,17,17,15,1,1,14};
            case 'A': case 'a': return new int[]{14,17,17,31,17,17,17};
            case 'C': case 'c': return new int[]{14,17,16,16,16,17,14};
            case 'E': case 'e': return new int[]{31,16,16,30,16,16,31};
            case 'r': return new int[]{0,0,22,25,16,16,16};
            case '-': return new int[]{0,0,0,31,0,0,0};
            case '.': return new int[]{0,0,0,0,0,12,12};
            case '+': return new int[]{0,4,4,31,4,4,0};
            case '%': return new int[]{17,2,4,8,17,0,0};
            case '=': return new int[]{0,31,0,31,0,0,0};
            case 'x': case '×': return new int[]{0,17,10,4,10,17,0};
            case '/': case '÷': return new int[]{4,0,31,0,4,0,0};
            default: return new int[]{0,0,0,0,0,0,0};
        }
    }
}
