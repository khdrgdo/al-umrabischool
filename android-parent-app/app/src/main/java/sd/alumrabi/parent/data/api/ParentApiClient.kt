package sd.alumrabi.parent.data.api

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.headers
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.json
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import sd.alumrabi.parent.data.model.DashboardPayload
import sd.alumrabi.parent.data.model.LoginResponse

class ParentApiClient(
    private val baseUrl: String = "https://c--8b91830b-7424-4960-81c7-67e94cdfd28d-prod.lovable.cloud",
    private val anonKey: String = "" // Injected safely at runtime or via build config
) {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        encodeDefaults = true
    }

    private val client = HttpClient(CIO) {
        install(ContentNegotiation) {
            json(json)
        }
    }

    suspend fun login(accountCode: String, pin: String): Result<LoginResponse> = withContext(Dispatchers.IO) {
        try {
            val response = client.post("$baseUrl/rest/v1/rpc/parent_app_login") {
                contentType(ContentType.Application.Json)
                headers {
                    append("apikey", anonKey)
                    append("Authorization", "Bearer $anonKey")
                }
                setBody(buildJsonObject {
                    put("_account_code", accountCode.trim().uppercase())
                    put("_code_or_pin", pin.trim())
                })
            }
            val body = response.body<LoginResponse>()
            Result.success(body)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun fetchDashboardData(authToken: String): Result<DashboardPayload> = withContext(Dispatchers.IO) {
        try {
            val response = client.post("$baseUrl/rest/v1/rpc/parent_get_dashboard_data") {
                contentType(ContentType.Application.Json)
                headers {
                    append("apikey", anonKey)
                    append("Authorization", "Bearer $authToken")
                }
            }
            val body = response.body<DashboardPayload>()
            Result.success(body)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
