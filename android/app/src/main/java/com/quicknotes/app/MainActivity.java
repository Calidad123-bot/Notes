package com.quicknotes.app;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.widget.Toast;

import androidx.webkit.WebViewAssetLoader;
import androidx.webkit.WebViewClientCompat;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

public class MainActivity extends Activity {
    private static final int FILE_CHOOSER_REQUEST_CODE = 1001;
    private static final int SAVE_DOCUMENT_REQUEST_CODE = 1002;
    private static final String START_URL =
            "https://appassets.androidplatform.net/assets/Notes.html";

    private WebView webView;
    private ValueCallback<Uri[]> fileChooserCallback;
    private String pendingExportContents;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        webView = new WebView(this);
        webView.setBackgroundColor(0xFFF4F7F6);
        setContentView(webView);

        WebViewAssetLoader assetLoader = new WebViewAssetLoader.Builder()
                .addPathHandler("/assets/", new WebViewAssetLoader.AssetsPathHandler(this))
                .build();

        webView.setWebViewClient(new WebViewClientCompat() {
            @Override
            public android.webkit.WebResourceResponse shouldInterceptRequest(
                    WebView view, android.webkit.WebResourceRequest request) {
                return assetLoader.shouldInterceptRequest(request.getUrl());
            }
        });
        webView.setWebChromeClient(new android.webkit.WebChromeClient() {
            @Override
            public boolean onShowFileChooser(
                    WebView view,
                    ValueCallback<Uri[]> callback,
                    FileChooserParams params) {
                if (fileChooserCallback != null) {
                    fileChooserCallback.onReceiveValue(null);
                }
                fileChooserCallback = callback;
                try {
                    startActivityForResult(params.createIntent(), FILE_CHOOSER_REQUEST_CODE);
                    return true;
                } catch (ActivityNotFoundException exception) {
                    fileChooserCallback = null;
                    callback.onReceiveValue(null);
                    Toast.makeText(MainActivity.this,
                            "No se encontró una app para seleccionar archivos.",
                            Toast.LENGTH_LONG).show();
                    return false;
                }
            }
        });

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(false);
        settings.setAllowContentAccess(true);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        webView.addJavascriptInterface(new AndroidBridge(), "AndroidBridge");
        webView.loadUrl(START_URL);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == FILE_CHOOSER_REQUEST_CODE) {
            if (fileChooserCallback != null) {
                Uri[] results = resultCode == RESULT_OK && data != null
                        ? android.webkit.WebChromeClient.FileChooserParams.parseResult(resultCode, data)
                        : null;
                fileChooserCallback.onReceiveValue(results);
                fileChooserCallback = null;
            }
            return;
        }

        if (requestCode == SAVE_DOCUMENT_REQUEST_CODE) {
            if (resultCode == RESULT_OK && data != null && data.getData() != null) {
                writeExport(data.getData());
            }
            pendingExportContents = null;
        }
    }

    private void requestExport(String fileName, String mimeType, String contents) {
        String safeFileName = fileName == null
                ? "quick_notes.json"
                : fileName.replaceAll("[^a-zA-Z0-9._-]", "_");
        String safeMimeType = "application/json".equals(mimeType)
                ? "application/json"
                : "text/plain";

        pendingExportContents = contents == null ? "" : contents;
        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType(safeMimeType);
        intent.putExtra(Intent.EXTRA_TITLE, safeFileName);
        try {
            startActivityForResult(intent, SAVE_DOCUMENT_REQUEST_CODE);
        } catch (ActivityNotFoundException exception) {
            pendingExportContents = null;
            Toast.makeText(this, "No se encontró una app para guardar el archivo.",
                    Toast.LENGTH_LONG).show();
        }
    }

    private void writeExport(Uri destination) {
        try (OutputStream output = getContentResolver().openOutputStream(destination)) {
            if (output == null) {
                throw new IOException("No se pudo abrir el archivo seleccionado.");
            }
            output.write(pendingExportContents.getBytes(StandardCharsets.UTF_8));
            Toast.makeText(this, "Notas exportadas correctamente.",
                    Toast.LENGTH_SHORT).show();
        } catch (IOException exception) {
            Toast.makeText(this, "No se pudieron exportar las notas: " + exception.getMessage(),
                    Toast.LENGTH_LONG).show();
        }
    }

    @Override
    protected void onDestroy() {
        if (fileChooserCallback != null) {
            fileChooserCallback.onReceiveValue(null);
            fileChooserCallback = null;
        }
        if (webView != null) {
            webView.removeJavascriptInterface("AndroidBridge");
            webView.destroy();
        }
        super.onDestroy();
    }

    private final class AndroidBridge {
        @JavascriptInterface
        public void saveText(String fileName, String mimeType, String contents) {
            runOnUiThread(() -> requestExport(fileName, mimeType, contents));
        }
    }
}
