package sd.alumrabi.parent.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material.icons.filled.School
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
import sd.alumrabi.parent.BuildConfig
import sd.alumrabi.parent.R
import sd.alumrabi.parent.data.DemoData
import sd.alumrabi.parent.data.api.AuthTokens
import sd.alumrabi.parent.data.api.ParentApiClient
import sd.alumrabi.parent.data.model.DashboardPayload
import sd.alumrabi.parent.ui.theme.*

@Composable
fun LoginScreen(
    onLoginSuccess: (tokens: AuthTokens, payload: DashboardPayload) -> Unit,
    onDemoLoginSuccess: (payload: DashboardPayload) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val apiClient = remember { ParentApiClient() }
    var accountCode by remember { mutableStateOf("") }
    var passwordOrPin by remember { mutableStateOf("") }
    var activationMode by remember { mutableStateOf(false) }
    var activationCode by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var isPasswordVisible by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    Column(
        modifier = Modifier.fillMaxSize().background(LavenderCanvas)
            .statusBarsPadding().navigationBarsPadding().imePadding()
            .verticalScroll(rememberScrollState()).padding(horizontal = 18.dp, vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Surface(Modifier.fillMaxWidth(), shape = RoundedCornerShape(30.dp), color = BurgundyPrimary) {
            Column(Modifier.padding(horizontal = 22.dp, vertical = 22.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(shape = RoundedCornerShape(20.dp), color = Color.White.copy(alpha = 0.12f), modifier = Modifier.size(68.dp)) {
                        Box(contentAlignment = Alignment.Center) {
                            Image(painterResource(R.drawable.brand_mark), "شعار العمرابي", Modifier.size(58.dp))
                        }
                    }
                    Spacer(Modifier.width(14.dp))
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("العمرابي", color = Color.White, fontSize = 23.sp, fontWeight = FontWeight.Bold)
                        Text("مؤسسة العمرابي التعليمية", color = Color.White.copy(alpha = 0.76f), fontSize = 12.sp)
                    }
                }
                HorizontalDivider(color = Color.White.copy(alpha = 0.16f))
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("كل ما يخص أبناءك، في مكان واحد", color = Color.White, fontSize = 21.sp, fontWeight = FontWeight.Bold, lineHeight = 30.sp)
                    Text("تابع النتائج والحضور والرسوم والإعلانات المعتمدة من المؤسسة.", color = Color.White.copy(alpha = 0.78f), fontSize = 13.sp, lineHeight = 21.sp)
                }
            }
        }

        Spacer(Modifier.height(18.dp))
        Surface(
            Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(26.dp),
            color = SurfaceWhite,
            border = androidx.compose.foundation.BorderStroke(1.dp, BorderLight),
            shadowElevation = 3.dp
        ) {
            Column(Modifier.padding(horizontal = 20.dp, vertical = 22.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(shape = CircleShape, color = BurgundyContainer, modifier = Modifier.size(44.dp)) {
                        Box(contentAlignment = Alignment.Center) { Icon(Icons.Default.School, null, tint = BurgundyPrimary) }
                    }
                    Spacer(Modifier.width(12.dp))
                    Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Text(if (activationMode) "تفعيل حساب ولي الأمر" else "تسجيل الدخول", color = TextPrimary, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                        Text(if (activationMode) "أدخل رمز التفعيل المرسل من إدارة المؤسسة." else "أدخل بيانات حسابك للمتابعة.", color = TextSecondary, fontSize = 12.sp)
                    }
                }

                OutlinedTextField(
                    value = accountCode,
                    onValueChange = { accountCode = it.uppercase(); errorMessage = null },
                    label = { Text("معرّف حساب ولي الأمر") },
                    leadingIcon = { Icon(Icons.Default.Person, null) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii, autoCorrect = false),
                    singleLine = true, modifier = Modifier.fillMaxWidth().heightIn(min = 58.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = BurgundyPrimary, unfocusedBorderColor = BorderLight, focusedLabelColor = BurgundyPrimary, focusedLeadingIconColor = BurgundyPrimary, unfocusedLeadingIconColor = TextSecondary)
                )

                if (activationMode) {
                    OutlinedTextField(
                        value = activationCode,
                        onValueChange = { activationCode = it.uppercase(); errorMessage = null },
                        label = { Text("رمز التفعيل من الإدارة") },
                        leadingIcon = { Icon(Icons.Default.Lock, null) },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii, autoCorrect = false),
                        singleLine = true, modifier = Modifier.fillMaxWidth().heightIn(min = 58.dp),
                        shape = RoundedCornerShape(16.dp)
                    )
                }

                OutlinedTextField(
                    value = passwordOrPin,
                    onValueChange = { passwordOrPin = it; errorMessage = null },
                    label = { Text(if (activationMode) "كلمة المرور الجديدة" else "كلمة المرور") },
                    leadingIcon = { Icon(Icons.Default.Lock, null) },
                    trailingIcon = {
                        IconButton(onClick = { isPasswordVisible = !isPasswordVisible }) {
                            Icon(if (isPasswordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility, if (isPasswordVisible) "إخفاء كلمة المرور" else "إظهار كلمة المرور")
                        }
                    },
                    visualTransformation = if (isPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrect = false),
                    singleLine = true, modifier = Modifier.fillMaxWidth().heightIn(min = 58.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = BurgundyPrimary, unfocusedBorderColor = BorderLight, focusedLabelColor = BurgundyPrimary, focusedLeadingIconColor = BurgundyPrimary, unfocusedLeadingIconColor = TextSecondary)
                )

                if (activationMode) {
                    OutlinedTextField(
                        value = confirmPassword,
                        onValueChange = { confirmPassword = it; errorMessage = null },
                        label = { Text("تأكيد كلمة المرور") },
                        leadingIcon = { Icon(Icons.Default.Lock, null) },
                        visualTransformation = PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrect = false),
                        singleLine = true, modifier = Modifier.fillMaxWidth().heightIn(min = 58.dp),
                        shape = RoundedCornerShape(16.dp)
                    )
                }

                AnimatedVisibility(visible = errorMessage != null, enter = fadeIn(), exit = fadeOut()) {
                    errorMessage?.let { message ->
                        Surface(color = StatusDangerBg, shape = RoundedCornerShape(14.dp), modifier = Modifier.fillMaxWidth()) {
                            Text(message, color = StatusDanger, fontSize = 12.sp, lineHeight = 19.sp, modifier = Modifier.padding(14.dp))
                        }
                    }
                }

                Button(
                    onClick = {
                        val code = accountCode.trim()
                        val password = passwordOrPin
                        if (code.isBlank() || password.isBlank()) {
                            errorMessage = "يرجى إدخال معرّف الحساب وكلمة المرور."
                            return@Button
                        }
                        if (BuildConfig.DEBUG && code.startsWith("DEMO-")) {
                            val demoPayload = DemoData.authenticate(code, password.trim())
                            if (demoPayload == null) errorMessage = "بيانات الاختبار لا تطابق الحساب. تحقق من كلمة المرور."
                            else { passwordOrPin = ""; onDemoLoginSuccess(demoPayload) }
                            return@Button
                        }
                        if (activationMode) {
                            if (activationCode.isBlank()) { errorMessage = "يرجى إدخال رمز التفعيل الذي سلّمته لك الإدارة."; return@Button }
                            if (password.length < 8) { errorMessage = "كلمة المرور يجب ألا تقل عن 8 أحرف."; return@Button }
                            if (password != confirmPassword) { errorMessage = "كلمتا المرور غير متطابقتين."; return@Button }
                        }
                        isLoading = true
                        errorMessage = null
                        coroutineScope.launch {
                            if (activationMode) {
                                val activation = apiClient.activate(code, activationCode, password)
                                if (activation.isFailure) {
                                    isLoading = false
                                    errorMessage = activation.exceptionOrNull()?.message ?: "تعذر إكمال التفعيل."
                                    return@launch
                                }
                            }
                            val signIn = apiClient.signIn(code, password)
                            val tokens = signIn.getOrNull()
                            if (tokens == null) {
                                isLoading = false
                                errorMessage = signIn.exceptionOrNull()?.message ?: "تعذر تسجيل الدخول."
                                return@launch
                            }
                            val dashboard = apiClient.fetchDashboard(tokens.accessToken)
                            val payload = dashboard.getOrNull()
                            isLoading = false
                            if (payload == null) {
                                errorMessage = dashboard.exceptionOrNull()?.message ?: "تعذر جلب بيانات ولي الأمر."
                                return@launch
                            }
                            passwordOrPin = ""
                            confirmPassword = ""
                            activationCode = ""
                            onLoginSuccess(tokens, payload)
                        }
                    },
                    enabled = !isLoading,
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = BurgundyPrimary, contentColor = Color.White)
                ) {
                    if (isLoading) CircularProgressIndicator(Modifier.size(21.dp), color = Color.White, strokeWidth = 2.dp)
                    else Text(if (activationMode) "تفعيل الحساب والمتابعة" else "الدخول إلى حسابي", fontSize = 15.sp, fontWeight = FontWeight.Bold)
                }

                TextButton(
                    onClick = {
                        activationMode = !activationMode
                        errorMessage = null
                        passwordOrPin = ""
                        confirmPassword = ""
                        activationCode = ""
                    },
                    modifier = Modifier.fillMaxWidth().heightIn(min = 48.dp)
                ) {
                    Text(if (activationMode) "لدي حساب مفعّل — العودة للدخول" else "لدي رمز تفعيل من إدارة المؤسسة", color = BurgundyPrimary, fontSize = 13.sp)
                }
            }
        }

        if (BuildConfig.DEBUG) {
            Spacer(Modifier.height(16.dp))
            Surface(
                Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(22.dp),
                color = Color(0xFFFFF9EC),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE8D7B7))
            ) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("معاينة النسخة التجريبية", color = BurgundyPrimary, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                    Text("الحسابات التالية محلية للاختبار ولا تتصل بقاعدة بيانات المؤسسة.", color = TextSecondary, fontSize = 11.sp, lineHeight = 17.sp)
                    DemoCredentialRow("أسرة متعددة الأبناء", DemoData.FAMILY_ACCOUNT) {
                        accountCode = DemoData.FAMILY_ACCOUNT
                        passwordOrPin = DemoData.PASSWORD
                        activationMode = false
                        errorMessage = null
                    }
                    HorizontalDivider(color = Color(0xFFE8D7B7))
                    DemoCredentialRow("ولي أمر — ابن واحد", DemoData.SINGLE_ACCOUNT) {
                        accountCode = DemoData.SINGLE_ACCOUNT
                        passwordOrPin = DemoData.PASSWORD
                        activationMode = false
                        errorMessage = null
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                        OutlinedButton(
                            onClick = {
                                val payload = DemoData.authenticate(DemoData.FAMILY_ACCOUNT, DemoData.PASSWORD)
                                if (payload != null) onDemoLoginSuccess(payload) else errorMessage = "تعذر تحميل بيانات الأسرة التجريبية."
                            },
                            modifier = Modifier.weight(1f).heightIn(min = 48.dp), shape = RoundedCornerShape(14.dp)
                        ) { Text("دخول الأسرة") }
                        OutlinedButton(
                            onClick = {
                                val payload = DemoData.authenticate(DemoData.SINGLE_ACCOUNT, DemoData.PASSWORD)
                                if (payload != null) onDemoLoginSuccess(payload) else errorMessage = "تعذر تحميل حساب ولي الأمر التجريبي."
                            },
                            modifier = Modifier.weight(1f).heightIn(min = 48.dp), shape = RoundedCornerShape(14.dp)
                        ) { Text("دخول فردي") }
                    }
                    Text("كلمة المرور للحسابين: " + DemoData.PASSWORD, color = TextSecondary, fontSize = 11.sp)
                }
            }
        }

        Spacer(Modifier.height(18.dp))
        Text("خصوصية الأبناء أولاً — لا تظهر البيانات إلا بعد اعتماد الربط من إدارة المؤسسة.", color = TextSecondary, fontSize = 11.sp, lineHeight = 18.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 14.dp))
        Spacer(Modifier.height(12.dp))
    }
}

@Composable
private fun DemoCredentialRow(title: String, account: String, onUse: () -> Unit) {
    Row(Modifier.fillMaxWidth().heightIn(min = 48.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(title, color = TextPrimary, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
            Text(account, color = TextSecondary, fontSize = 11.sp)
        }
        TextButton(onClick = onUse) { Text("استخدم", color = BurgundyPrimary, fontSize = 12.sp) }
    }
}
