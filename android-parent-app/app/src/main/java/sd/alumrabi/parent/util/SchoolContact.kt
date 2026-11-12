package sd.alumrabi.parent.util

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import sd.alumrabi.parent.R

object SchoolContact {
    /** رقم المدرسة يأتي من النظام (إعدادات المدرسة)؛ احتياطياً strings.xml، وإن كان فارغاً يفتح واتساب لاختيار جهة الاتصال. */
    fun openWhatsApp(context: Context, schoolNumber: String?, guardianName: String, accountCode: String?, childName: String?) {
        val number = (schoolNumber?.filter { it.isDigit() }?.takeIf { it.isNotBlank() }
            ?: context.getString(R.string.school_whatsapp_number).filter { it.isDigit() })
        val sb = StringBuilder("السلام عليكم، أنا ").append(guardianName)
        if (!childName.isNullOrBlank()) sb.append("، ولي أمر الطالب/ة ").append(childName)
        if (!accountCode.isNullOrBlank()) sb.append(" (رقم ولي الأمر ").append(accountCode).append(")")
        sb.append(".")
        val text = Uri.encode(sb.toString())
        val url = if (number.isBlank()) "https://wa.me/?text=$text" else "https://wa.me/$number?text=$text"
        try {
            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (_: Exception) {
            Toast.makeText(context, "تعذّر فتح واتساب على هذا الجهاز", Toast.LENGTH_SHORT).show()
        }
    }
}
