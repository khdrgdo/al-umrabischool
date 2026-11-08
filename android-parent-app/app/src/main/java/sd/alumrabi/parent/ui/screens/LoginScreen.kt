package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.graphics.Brush
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import sd.alumrabi.parent.data.api.AuthTokens
import sd.alumrabi.parent.data.api.ParentApiClient
import sd.alumrabi.parent.data.model.DashboardPayload
import sd.alumrabi.parent.ui.components.OmrabiSymbol
import sd.alumrabi.parent.ui.components.OutlineButton
import sd.alumrabi.parent.ui.components.PrimaryButton
import sd.alumrabi.parent.ui.theme.*

@Composable
fun LoginScreen(
    onLoginSuccess: (tokens: AuthTokens, payload: DashboardPayload) -> Unit,
    onDemo: (() -> Unit)? = null
) {
    SystemBars(
        statusBar = Crimson700,
        darkIcons = false,
        navigationBar = Canvas,
        navigationIconsDark = true
    )
    val scope = rememberCoroutineScope()
    val apiClient = remember { ParentApiClient() }
    val focus = LocalFocusManager.current

    var accountCode by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    // وضع التفعيل: أول دخول أو نسيان كلمة المرور؛ يتطلب رمزاً مؤقتاً تسلّمه الإدارة.
    var activationMode by remember { mutableStateOf(false) }
    var activationCode by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var showPassword by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    fun submit() {
        if (isLoading) return
        focus.clearFocus()
        val code = accountCode.trim()
        val pw = password

        if (code.isBlank() || pw.isBlank()) {
            errorMessage = "أدخل معرّف الحساب وكلمة المرور."
            return
        }
        if (activationMode) {
            if (activationCode.isBlank()) {
                errorMessage = "أدخل رمز التفعيل الذي سلّمته لك إدارة المدرسة."
                return
            }
            if (pw.length < 8) {
                errorMessage = "كلمة المرور يجب ألا تقل عن 8 أحرف."
                return
            }
            if (pw != confirmPassword) {
                errorMessage = "كلمتا المرور غير متطابقتين."
                return
            }
        }

        isLoading = true
        errorMessage = null

        scope.launch {
            if (activationMode) {
                val act = apiClient.activate(code, activationCode, pw)
                if (act.isFailure) {
                    isLoading = false
                    errorMessage = act.exceptionOrNull()?.message ?: "تعذر إكمال التفعيل."
                    return@launch
                }
            }
            val signIn = apiClient.signIn(code, pw)
            val tokens = signIn.getOrNull()
            if (tokens == null) {
                isLoading = false
                errorMessage = signIn.exceptionOrNull()?.message ?: "تعذر تسجيل الدخول."
                return@launch
            }
            val dash = apiClient.fetchDashboard(tokens.accessToken)
            val payload = dash.getOrNull()
            isLoading = false
            if (payload == null) {
                errorMessage = dash.exceptionOrNull()?.message ?: "تعذر جلب بيانات ولي الأمر."
                return@launch
            }
            // لا تُحفظ كلمة المرور ولا رمز التفعيل في أي مكان
            password = ""
            confirmPassword = ""
            activationCode = ""
            onLoginSuccess(tokens, payload)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Canvas)
            .verticalScroll(rememberScrollState())
    ) {
        // رأس الهوية
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    Brush.verticalGradient(listOf(Crimson800, Crimson700, Crimson600)),
                    RoundedCornerShape(bottomStart = 32.dp, bottomEnd = 32.dp)
                )
                .padding(start = 24.dp, end = 24.dp, top = 36.dp, bottom = 44.dp)
        ) {
            Column {
                OmrabiSymbol(size = 56.dp, tint = OnBrand, description = "شعار العمرابي")
                Spacer(Modifier.height(16.dp))
                Text(
                    "العمرابي",
                    style = MaterialTheme.typography.headlineSmall,
                    color = OnBrand
                )
                Text(
                    "بوابة أولياء الأمور",
                    style = MaterialTheme.typography.bodyMedium,
                    color = OnBrand.copy(alpha = 0.85f)
                )
            }
        }

        Column(Modifier.padding(horizontal = 24.dp, vertical = 24.dp)) {
            Text(
                if (activationMode) "تفعيل الحساب" else "تسجيل الدخول",
                style = MaterialTheme.typography.titleLarge,
                color = Ink900
            )
            Spacer(Modifier.height(4.dp))
            Text(
                if (activationMode) {
                    "أدخل المعرّف والرمز الذي أعطتك إياه إدارة المدرسة، ثم اختر كلمة مرور جديدة."
                } else {
                    "استخدم معرّف الحساب الذي سلّمته لك المدرسة."
                },
                style = MaterialTheme.typography.bodyMedium,
                color = Ink700
            )
            Spacer(Modifier.height(20.dp))

            LoginField(
                value = accountCode,
                onValueChange = {
                    accountCode = it.uppercase()
                    errorMessage = null
                },
                label = "معرّف الحساب",
                placeholder = "PAR-10101",
                ltr = true
            )

            if (activationMode) {
                Spacer(Modifier.height(12.dp))
                LoginField(
                    value = activationCode,
                    onValueChange = {
                        activationCode = it.uppercase()
                        errorMessage = null
                    },
                    label = "رمز التفعيل",
                    placeholder = "XXXX-XXXX-XXXX-XXXX",
                    ltr = true
                )
            }

            Spacer(Modifier.height(12.dp))
            LoginField(
                value = password,
                onValueChange = {
                    password = it
                    errorMessage = null
                },
                label = if (activationMode) "كلمة المرور الجديدة (8 أحرف فأكثر)" else "كلمة المرور",
                isPassword = true,
                showPassword = showPassword,
                onTogglePassword = { showPassword = !showPassword },
                imeAction = if (activationMode) ImeAction.Next else ImeAction.Done,
                onDone = { submit() }
            )

            if (activationMode) {
                Spacer(Modifier.height(12.dp))
                LoginField(
                    value = confirmPassword,
                    onValueChange = {
                        confirmPassword = it
                        errorMessage = null
                    },
                    label = "تأكيد كلمة المرور",
                    isPassword = true,
                    showPassword = showPassword,
                    imeAction = ImeAction.Done,
                    onDone = { submit() }
                )
            }

            val error = errorMessage
            if (error != null) {
                Spacer(Modifier.height(12.dp))
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .semantics { liveRegion = LiveRegionMode.Polite },
                    shape = Radius.field,
                    color = NegativeBg
                ) {
                    Text(
                        error,
                        style = MaterialTheme.typography.bodySmall,
                        color = Negative,
                        modifier = Modifier.padding(12.dp)
                    )
                }
            }

            Spacer(Modifier.height(20.dp))
            PrimaryButton(
                text = if (activationMode) "تفعيل الحساب والدخول" else "دخول",
                onClick = { submit() },
                modifier = Modifier.fillMaxWidth(),
                loading = isLoading
            )

            Spacer(Modifier.height(4.dp))
            TextButton(
                onClick = {
                    activationMode = !activationMode
                    errorMessage = null
                    password = ""
                    confirmPassword = ""
                    activationCode = ""
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    if (activationMode) {
                        "لدي حساب مفعّل — العودة لتسجيل الدخول"
                    } else {
                        "أول مرة؟ أو نسيت كلمة المرور؟ فعّل برمز من الإدارة"
                    },
                    style = MaterialTheme.typography.labelLarge,
                    color = Crimson700
                )
            }

            if (onDemo != null) {
                Spacer(Modifier.height(8.dp))
                OutlineButton(
                    text = "تجربة ببيانات تجريبية (للاختبار فقط)",
                    onClick = onDemo,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            Spacer(Modifier.height(16.dp))
            Text(
                "الاتصال بخادم المدرسة مشفّر، ولا تُحفظ كلمة المرور على هذا الجهاز.",
                style = MaterialTheme.typography.bodySmall,
                color = Ink500
            )
        }
    }
}

@Composable
private fun LoginField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    placeholder: String? = null,
    ltr: Boolean = false,
    isPassword: Boolean = false,
    showPassword: Boolean = false,
    onTogglePassword: (() -> Unit)? = null,
    imeAction: ImeAction = ImeAction.Next,
    onDone: () -> Unit = {}
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label) },
        placeholder = {
            if (placeholder != null) {
                Text(
                    placeholder,
                    style = MaterialTheme.typography.bodyLarge.copy(textDirection = TextDirection.Ltr),
                    color = Ink500
                )
            }
        },
        singleLine = true,
        textStyle = MaterialTheme.typography.bodyLarge.copy(
            textDirection = if (ltr) TextDirection.Ltr else TextDirection.Content
        ),
        visualTransformation = if (isPassword && !showPassword) PasswordVisualTransformation() else VisualTransformation.None,
        keyboardOptions = KeyboardOptions(
            keyboardType = if (isPassword) KeyboardType.Password else KeyboardType.Ascii,
            imeAction = imeAction,
            autoCorrect = false
        ),
        keyboardActions = KeyboardActions(onDone = { onDone() }),
        trailingIcon = {
            if (isPassword && onTogglePassword != null) {
                IconButton(onClick = onTogglePassword) {
                    Icon(
                        if (showPassword) Icons.Outlined.VisibilityOff else Icons.Outlined.Visibility,
                        contentDescription = if (showPassword) "إخفاء كلمة المرور" else "إظهار كلمة المرور",
                        tint = Ink700
                    )
                }
            }
        },
        shape = Radius.field,
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = Crimson600,
            unfocusedBorderColor = LineStrong,
            focusedLabelColor = Crimson700,
            unfocusedLabelColor = Ink500,
            cursorColor = Crimson600,
            focusedContainerColor = Paper,
            unfocusedContainerColor = Paper
        ),
        modifier = Modifier.fillMaxWidth()
    )
}
