package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material.icons.outlined.School
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import sd.alumrabi.parent.R
import sd.alumrabi.parent.data.api.AuthTokens
import sd.alumrabi.parent.data.api.ParentApiClient
import sd.alumrabi.parent.data.model.DashboardPayload
import sd.alumrabi.parent.ui.theme.*

@Composable
fun LoginScreen(
    onLoginSuccess: (tokens: AuthTokens, payload: DashboardPayload) -> Unit
) {
    val scope = rememberCoroutineScope()
    val api = remember { ParentApiClient() }
    var accountCode by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var activationCode by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var activationMode by remember { mutableStateOf(false) }
    var passwordVisible by remember { mutableStateOf(false) }
    var loading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    Column(
        Modifier.fillMaxSize().background(AppCanvas).statusBarsPadding().navigationBarsPadding().imePadding().verticalScroll(rememberScrollState())
            .padding(horizontal = 22.dp, vertical = 22.dp),
        horizontalAlignment = Alignment.Start
    ) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Surface(shape = RoundedCornerShape(18.dp), color = Color.White, border = BorderStroke(1.dp, AppBorder), modifier = Modifier.size(58.dp)) {
                Image(painterResource(R.drawable.ic_alumrabi_mark), "شعار العمرابي", Modifier.padding(7.dp))
            }
            Spacer(Modifier.width(13.dp))
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text("العمرابي", color = AppInk, fontSize = 21.sp, fontWeight = FontWeight.ExtraBold)
                Text("AL-OMRABI  /  FAMILY", color = AppMuted, fontSize = 9.sp, letterSpacing = 2.2.sp, fontWeight = FontWeight.SemiBold)
            }
            Spacer(Modifier.weight(1f))
            Surface(shape = CircleShape, color = AppRedSoft) {
                Icon(Icons.Outlined.School, null, tint = AppRed, modifier = Modifier.padding(11.dp).size(19.dp))
            }
        }

        Spacer(Modifier.height(42.dp))
        Text(if (activationMode) "تفعيل حسابك" else "مرحباً بعودتك", color = AppInk, fontSize = 29.sp, fontWeight = FontWeight.ExtraBold, lineHeight = 38.sp)
        Spacer(Modifier.height(8.dp))
        Text(
            if (activationMode) "أدخل بيانات التفعيل التي استلمتها من إدارة المؤسسة لإنشاء كلمة مرورك."
            else "مساحة آمنة تجمع متابعة أبنائك الدراسية في مكان واحد.",
            color = AppMuted, fontSize = 14.sp, lineHeight = 23.sp
        )
        Spacer(Modifier.height(28.dp))

        Surface(
            modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(26.dp),
            color = Color.White, border = BorderStroke(1.dp, AppBorder)
        ) {
            Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(15.dp)) {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(if (activationMode) "بيانات التفعيل" else "بيانات الدخول", color = AppInk, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                    Text("جميع الحقول المطلوبة موضحة أدناه", color = AppMuted, fontSize = 11.sp)
                }
                OutlinedTextField(
                    value = accountCode, onValueChange = { accountCode = it.uppercase(); error = null },
                    modifier = Modifier.fillMaxWidth(), singleLine = true,
                    label = { Text("معرّف حساب ولي الأمر") }, leadingIcon = { Icon(Icons.Outlined.Person, null) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii, autoCorrect = false),
                    shape = RoundedCornerShape(15.dp),
                    colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = AppRed, focusedLabelColor = AppRed, focusedLeadingIconColor = AppRed)
                )
                if (activationMode) {
                    OutlinedTextField(
                        value = activationCode, onValueChange = { activationCode = it.uppercase(); error = null },
                        modifier = Modifier.fillMaxWidth(), singleLine = true,
                        label = { Text("رمز التفعيل من الإدارة") }, leadingIcon = { Icon(Icons.Outlined.Lock, null) },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii, autoCorrect = false),
                        shape = RoundedCornerShape(15.dp), colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = AppRed)
                    )
                }
                OutlinedTextField(
                    value = password, onValueChange = { password = it; error = null },
                    modifier = Modifier.fillMaxWidth(), singleLine = true,
                    label = { Text(if (activationMode) "كلمة المرور الجديدة" else "كلمة المرور") },
                    leadingIcon = { Icon(Icons.Outlined.Lock, null) },
                    trailingIcon = { IconButton(onClick = { passwordVisible = !passwordVisible }) { Icon(if (passwordVisible) Icons.Outlined.VisibilityOff else Icons.Outlined.Visibility, if (passwordVisible) "إخفاء كلمة المرور" else "إظهار كلمة المرور") } },
                    visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrect = false),
                    shape = RoundedCornerShape(15.dp), colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = AppRed)
                )
                if (activationMode) {
                    OutlinedTextField(
                        value = confirmPassword, onValueChange = { confirmPassword = it; error = null },
                        modifier = Modifier.fillMaxWidth(), singleLine = true,
                        label = { Text("تأكيد كلمة المرور") }, leadingIcon = { Icon(Icons.Outlined.Lock, null) },
                        visualTransformation = PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrect = false),
                        shape = RoundedCornerShape(15.dp), colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = AppRed)
                    )
                }
                AnimatedVisibility(error != null, enter = fadeIn(), exit = fadeOut()) {
                    error?.let { Surface(color = StatusDangerBg, shape = RoundedCornerShape(12.dp)) {
                        Text(it, Modifier.fillMaxWidth().padding(13.dp), color = StatusDanger, fontSize = 12.sp, lineHeight = 19.sp)
                    } }
                }
                Button(
                    onClick = {
                        val code = accountCode.trim()
                        if (code.isBlank() || password.isBlank()) { error = "يرجى إدخال معرّف الحساب وكلمة المرور."; return@Button }
                        if (activationMode) {
                            if (activationCode.isBlank()) { error = "يرجى إدخال رمز التفعيل الذي سلّمته لك الإدارة."; return@Button }
                            if (password.length < 8) { error = "كلمة المرور يجب ألا تقل عن 8 أحرف."; return@Button }
                            if (password != confirmPassword) { error = "كلمتا المرور غير متطابقتين."; return@Button }
                        }
                        loading = true; error = null
                        scope.launch {
                            if (activationMode) {
                                val activation = api.activate(code, activationCode, password)
                                if (activation.isFailure) { loading = false; error = activation.exceptionOrNull()?.message ?: "تعذر إكمال التفعيل."; return@launch }
                            }
                            val signIn = api.signIn(code, password)
                            val tokens = signIn.getOrNull()
                            if (tokens == null) { loading = false; error = signIn.exceptionOrNull()?.message ?: "تعذر تسجيل الدخول."; return@launch }
                            val dashboard = api.fetchDashboard(tokens.accessToken)
                            val payload = dashboard.getOrNull()
                            loading = false
                            if (payload == null) { error = dashboard.exceptionOrNull()?.message ?: "تعذر جلب بيانات ولي الأمر."; return@launch }
                            password = ""; confirmPassword = ""; activationCode = ""
                            onLoginSuccess(tokens, payload)
                        }
                    },
                    enabled = !loading, modifier = Modifier.fillMaxWidth().height(54.dp),
                    shape = RoundedCornerShape(15.dp), colors = ButtonDefaults.buttonColors(containerColor = AppRed)
                ) {
                    if (loading) CircularProgressIndicator(Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp)
                    else Text(if (activationMode) "تفعيل الحساب والمتابعة" else "الدخول إلى حسابي", fontSize = 14.sp, fontWeight = FontWeight.Bold)
                }
                TextButton(
                    onClick = { activationMode = !activationMode; error = null; password = ""; confirmPassword = ""; activationCode = "" },
                    modifier = Modifier.fillMaxWidth().heightIn(min = 46.dp)
                ) {
                    Text(if (activationMode) "لدي حساب مفعّل — تسجيل الدخول" else "لدي رمز تفعيل من إدارة المؤسسة", color = AppRed, fontSize = 12.sp)
                }
            }
        }

        Spacer(Modifier.height(24.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Outlined.Lock, null, tint = AppMuted, modifier = Modifier.size(14.dp))
            Spacer(Modifier.width(7.dp))
            Text("خصوصية الأبناء أولاً · بيانات معتمدة فقط", color = AppMuted, fontSize = 10.sp, textAlign = TextAlign.Center)
        }
        Spacer(Modifier.height(12.dp))
    }
}

