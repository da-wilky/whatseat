package de.whatseat.whatseat

import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import android.view.WindowManager
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.FileNotFoundException
import java.io.IOException
import java.io.InputStream

private const val MAX_READ_BYTES = 64 * 1024 * 1024

// FlutterFragmentActivity is required by local_auth's BiometricPrompt.
class MainActivity : FlutterFragmentActivity() {
    private var pendingPick: MethodChannel.Result? = null

    private val pickFolder = registerForActivityResult(ActivityResultContracts.OpenDocumentTree()) { tree ->
        val result = pendingPick ?: return@registerForActivityResult
        pendingPick = null
        if (tree == null) {
            result.success(null)
            return@registerForActivityResult
        }
        try {
            // Without it, access ends with this activity and automatic backups would fail after a restart.
            contentResolver.takePersistableUriPermission(
                tree, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
            result.success(mapOf("uri" to tree.toString(), "name" to folderName(tree)))
        } catch (e: Exception) {
            result.error("folder", e.message ?: e.javaClass.simpleName, null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "whatseat/window").setMethodCallHandler { call, result ->
            if (call.method == "setSecure") {
                if (call.arguments as Boolean) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(messenger, "whatseat/folder").setMethodCallHandler { call, result ->
            if (call.method == "pick") {
                if (pendingPick != null) {
                    result.error("folder", "Folder picker already open", null)
                } else {
                    pendingPick = result
                    pickFolder.launch(null)
                }
                return@setMethodCallHandler
            }
            val tree = Uri.parse(call.argument<String>("uri"))
            val name = call.argument<String>("name")
            if (call.method == "release") {
                try {
                    contentResolver.releasePersistableUriPermission(
                        tree, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    )
                } catch (e: SecurityException) {
                    // Not held (any more): nothing to give back.
                }
                result.success(null)
                return@setMethodCallHandler
            }
            // Provider apps may go to the network, so the work stays off the UI thread.
            Thread {
                try {
                    val value: Any? = when (call.method) {
                        "list" -> children(tree).keys.toList()
                        "read" -> {
                            val doc = children(tree)[name] ?: throw FileNotFoundException(name)
                            contentResolver.openInputStream(doc)!!.use { readLimited(it) }
                        }
                        "write" -> {
                            write(tree, name!!, call.argument<ByteArray>("bytes")!!)
                            null
                        }
                        "delete" -> {
                            children(tree)[name]?.let { DocumentsContract.deleteDocument(contentResolver, it) }
                            null
                        }
                        else -> {
                            runOnUiThread { result.notImplemented() }
                            return@Thread
                        }
                    }
                    runOnUiThread { result.success(value) }
                } catch (e: Exception) {
                    runOnUiThread { result.error("folder", e.message ?: e.javaClass.simpleName, null) }
                }
            }.start()
        }
    }

    private fun folderUri(tree: Uri) = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))

    private fun folderName(tree: Uri): String =
        contentResolver.query(folderUri(tree), arrayOf(Document.COLUMN_DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) it.getString(0) else null
        } ?: tree.lastPathSegment ?: tree.toString()

    private fun children(tree: Uri): Map<String, Uri> {
        val query = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val found = mutableMapOf<String, Uri>()
        contentResolver.query(query, arrayOf(Document.COLUMN_DOCUMENT_ID, Document.COLUMN_DISPLAY_NAME), null, null, null)
            ?.use { while (it.moveToNext()) found[it.getString(1)] = DocumentsContract.buildDocumentUriUsingTree(tree, it.getString(0)) }
        return found
    }

    // The folder may belong to a cloud app; a far larger file than any backup would only exhaust memory.
    private fun readLimited(input: InputStream): ByteArray {
        val out = ByteArrayOutputStream()
        val buffer = ByteArray(64 * 1024)
        while (true) {
            val read = input.read(buffer)
            if (read < 0) return out.toByteArray()
            out.write(buffer, 0, read)
            if (out.size() > MAX_READ_BYTES) throw IOException("File too large")
        }
    }

    private fun write(tree: Uri, name: String, bytes: ByteArray) {
        children(tree)[name]?.let { existing ->
            try {
                contentResolver.openOutputStream(existing, "wt")!!.use { it.write(bytes) }
                return
            } catch (e: IllegalArgumentException) {
                // Mode "wt" unsupported by this provider: replace the file instead. Other errors, like a
                // dropped connection, propagate so the existing backup stays.
                DocumentsContract.deleteDocument(contentResolver, existing)
            } catch (e: UnsupportedOperationException) {
                DocumentsContract.deleteDocument(contentResolver, existing)
            }
        }
        val created = DocumentsContract.createDocument(contentResolver, folderUri(tree), "application/json", name)
            ?: throw IOException("Could not create $name")
        contentResolver.openOutputStream(created)!!.use { it.write(bytes) }
    }
}
