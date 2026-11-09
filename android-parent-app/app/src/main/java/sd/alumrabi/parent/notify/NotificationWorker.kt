package sd.alumrabi.parent.notify

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import sd.alumrabi.parent.data.api.ParentApiClient
import sd.alumrabi.parent.data.local.SessionManager

/** يفحص الجديد في الخلفية ويعرض إشعاراً لكل ما لم يُعرض من قبل. */
class NotificationWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val sm = SessionManager(applicationContext)
        if (!sm.isLoggedIn()) return Result.success()
        var tokens = sm.getTokens() ?: return Result.success()
        val api = ParentApiClient()
        if (tokens.isExpiringSoon()) {
            val renewed = api.refreshSession(tokens.refreshToken).getOrNull() ?: return Result.success()
            sm.saveTokens(renewed)
            tokens = renewed
        }
        val payload = api.fetchDashboard(tokens.accessToken).getOrNull() ?: return Result.success()
        sm.saveSession(payload.guardian, payload.children)
        sm.saveContent(payload.announcements, payload.events)

        val keys = Notifier.keys(payload)
        if (!sm.hasNotifyBaseline()) {
            // أول فحص: نسجّل الموجود دون إزعاج، والإشعارات تبدأ مما يأتي بعده.
            sm.addNotified(keys)
            return Result.success()
        }
        val fresh = keys - sm.getNotifiedIds()
        if (fresh.isNotEmpty()) {
            Notifier.post(applicationContext, payload, fresh)
            sm.addNotified(fresh)
        }
        return Result.success()
    }
}
