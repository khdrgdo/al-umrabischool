package sd.alumrabi.parent.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
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
        modifier = Modifier
            .fillMaxSize()
            .background(LavenderCanvas)
            .statusBarsPadding()
            .navigationBarsPadding()
            .imePadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 28.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(10.dp))

        Image(
            painter = painterResource(R.drawable.ic_launcher_foreground),
            contentDescription = "شعار تطبيق العمرابي",
            modifier = Modifier.size(92.dp)
        )

        Spacer(Modifier.height(12.dp))

        Text(
            text = "مؤسسة العمرابي التعليمية",
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            color = BurgundyPrimary,
            textAlign = TextAlign.Center
        )
        Text(
            text = "بوابة أولياء الأمور",
            fontSize = 14.sp,
            color = TextSecondary,
            modifier = Modifier.padding(top = 5.dp)
        )

        Spacer(Modifier.height(28.dp))

        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, BorderLight, RoundedCornerShape(22.dp)),
            shape = RoundedCornerShape(22.dp),
            color = SurfaceWhite,
            shadowElevation = 2.dp
        ) {
            Column(
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 22.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = if (activationMode) "تفعيل حساب ولي الأمر" else "مرحباً بعودتك",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                Text(
                    text = if (activationMode)
                        "أدخل بيانات الحساب ورمز التفعيل الذي تسلّمته من الإدارة."
                    else
                        "سجّل الدخول لمتابعة شؤون أبنائك الدراسية.",
                    fontSize = 12.sp,
                    color = TextSecondary,
                    lineHeight = 19.sp
                )

                OutlinedTextField(
                    value = accountCode,
                    onValueChange = {
                        accountCode = it.uppercase()
                        errorMessage = null
                    },
                    label = { Text("معرّف الحساب") },
                    leadingIcon = { Icon(Icons.Default.Person, contentDescription = null, tint = BurgundyPrimary) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii, autoCorrect = false),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = BurgundyPrimary,
                        unfocusedBorderColor = BorderLight,
                        focusedLabelColor = BurgundyPrimary
                    )
                )

                if (activationMode) {
                    OutlinedTextField(
                        value = activationCode,
                        onValueChange = {
                            activationCode = it.uppercase()
                            errorMessage = null
                        },
                        label = { Text("رمز التفعيل من الإدارة") },
                        leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null, tint = BurgundyPrimary) },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii, autoCorrect = false),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = BurgundyPrimary,
                            unfocusedBorderColor = BorderLight
                        )
                    )
                }

                OutlinedTextField(
                    value = passwordOrPin,
                    onValueChange = {
                        passwordOrPin = it
                        errorMessage = null
                    },
                    label = { Text(if (activationMode) "كلمة المرور الجديدة" else "كلمة المرور") },
                    leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null, tint = BurgundyPrimary) },
                    trailingIcon = {
                        IconButton(onClick = { isPasswordVisible = !isPasswordVisible }) {
                            Icon(
                                imageVector = if (isPasswordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                contentDescription = if (isPasswordVisible) "إخفاء كلمة المرور" else "إظهار كلمة المرور",
                                tint = TextSecondary
                            )
                        }
                    },
                    visualTransformation = if (isPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrect = false),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = BurgundyPrimary,
                        unfocusedBorderColor = BorderLight
                    )
                )

                if (activationMode) {
                    OutlinedTextField(
                        value = confirmPassword,
                        onValueChange = {
                            confirmPassword = it
                            errorMessage = null
                        },
                        label = { Text("تأكيد كلمة المرور") },
                        leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null, tint = BurgundyPrimary) },
                        visualTransformation = PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrect = false),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = BurgundyPrimary,
                            unfocusedBorderColor = BorderLight
                        )
                    )
                }

                AnimatedVisibility(
                    visible = errorMessage != null,
                    enter = fadeIn(),
                    exit = fadeOut()
                ) {
                    errorMessage?.let { message ->
                        Surface(
                            color = StatusDangerBg,
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = message,
                                color = StatusDanger,
                                fontSize = 12.sp,
                                modifier = Modifier.padding(12.dp),
                                lineHeight = 18.sp
                            )
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
                            val demoPayload = DemoData.authenticate(code, password)
                            if (demoPayload == null) {
                                errorMessage = "بيانات الحساب التجريبي غير صحيحة."
                            } else {
                                passwordOrPin = ""
                                onDemoLoginSuccess(demoPayload)
                            }
                            return@Button
                        }

                        if (activationMode) {
                            if (activationCode.isBlank()) {
                                errorMessage = "يرجى إدخال رمز التفعيل الذي سلّمته لك الإدارة."
                                return@Button
                            }
                            if (password.length < 8) {
                                errorMessage = "كلمة المرور يجب ألا تقل عن 8 أحرف."
                                return@Button
                            }
                            if (password != confirmPassword) {
                                errorMessage = "كلمتا المرور غير متطابقتين."
                                return@Button
                            }
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
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = BurgundyPrimary)
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = Color.White,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text(
                            text = if (activationMode) "تفعيل الحساب والدخول" else "تسجيل الدخول",
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                TextButton(
                    onClick = {
                        activationMode = !activationMode
                        errorMessage = null
                        passwordOrPin = ""
                        confirmPassword = ""
                        activationCode = ""
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = if (activationMode)
                            "لدي حساب مفعّل — العودة للدخول"
                        else
                            "لدي رمز تفعيل من إدارة المؤسسة؟",
                        color = BurgundyPrimary,
                        fontSize = 12.sp
                    )
                }
            }
        }

        if (BuildConfig.DEBUG) {
            Spacer(Modifier.height(18.dp))
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, Color(0xFFE7D9B7), RoundedCornerShape(18.dp)),
                shape = RoundedCornerShape(18.dp),
                color = Color(0xFFFFFCF5)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        "بيانات اختبار محلية",
                        color = BurgundyPrimary,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        "هذه الحسابات تعمل داخل نسخة الاختبار فقط ولا تتصل بقاعدة البيانات.",
                        color = TextSecondary,
                        fontSize = 11.sp,
                        lineHeight = 17.sp
                    )
                    DemoCredentialRow(
                        title = "أسرة متعددة الأبناء",
                        account = DemoData.FAMILY_ACCOUNT,
                        onUse = {
                            accountCode = DemoData.FAMILY_ACCOUNT
                            passwordOrPin = DemoData.PASSWORD
                            activationMode = false
                            errorMessage = null
                        }
                    )
                    DemoCredentialRow(
                        title = "ولي أمر — ابن واحد",
                        account = DemoData.SINGLE_ACCOUNT,
                        onUse = {
                            accountCode = DemoData.SINGLE_ACCOUNT
                            passwordOrPin = DemoData.PASSWORD
                            activationMode = false
                            errorMessage = null
                        }
                    )
                    Text(
                        "كلمة المرور للحسابين: ${DemoData.PASSWORD}",
                        color = TextPrimary,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }

        Spacer(Modifier.height(22.dp))
        Text(
            text = "بيانات الأبناء لا تظهر إلا بعد اعتماد ارتباط ولي الأمر من إدارة المؤسسة.",
            color = TextSecondary,
            fontSize = 11.sp,
            lineHeight = 17.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 12.dp)
        )
        Spacer(Modifier.height(12.dp))
    }
}

@Composable
private fun DemoCredentialRow(
    title: String,
    account: String,
    onUse: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(title, color = TextPrimary, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
            Text(account, color = TextSecondary, fontSize = 11.sp)
        }
        TextButton(onClick = onUse) {
            Text("استخدم", color = BurgundyPrimary, fontSize = 11.sp)
        }
    }
}
