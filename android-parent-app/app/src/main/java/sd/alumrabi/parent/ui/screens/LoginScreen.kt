package sd.alumrabi.parent.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import sd.alumrabi.parent.data.api.AuthTokens
import sd.alumrabi.parent.data.api.ParentApiClient
import sd.alumrabi.parent.data.model.DashboardPayload
import sd.alumrabi.parent.ui.theme.*

@Composable
fun LoginScreen(
    onLoginSuccess: (tokens: AuthTokens, payload: DashboardPayload) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val apiClient = remember { ParentApiClient() }

    var accountCode by remember { mutableStateOf("") }
    var passwordOrPin by remember { mutableStateOf("") }
    // وضع التفعيل: أول دخول أو نسيان كلمة المرور؛ يتطلب رمزاً شخصياً مؤقتاً تسلّمه الإدارة.
    var activationMode by remember { mutableStateOf(false) }
    var activationCode by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var isPinVisible by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(LavenderCanvas)
            .padding(horizontal = 24.dp, vertical = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Institutional Heraldic Emblem
        Surface(
            shape = RoundedCornerShape(18.dp),
            color = BurgundyPrimary,
            modifier = Modifier.size(76.dp),
            shadowElevation = 4.dp
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text(
                    text = "ع",
                    color = Color.White,
                    fontSize = 42.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        Text(
            text = "مؤسسة العمرابي التعليمية",
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
            color = BurgundyPrimary
        )

        Text(
            text = "بوابة أولياء الأمور والمتابعة الأكاديمية",
            fontSize = 12.sp,
            color = TextSecondary,
            modifier = Modifier.padding(top = 4.dp)
        )

        Spacer(modifier = Modifier.height(28.dp))

        // Main Login Container (Clean, Anti-AI: Subtle border, crisp typography, no heavy nested cards)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(SurfaceWhite, RoundedCornerShape(14.dp))
                .border(1.dp, BorderLight, RoundedCornerShape(14.dp))
                .padding(20.dp)
        ) {
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "تسجيل الدخول والتفعيل",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )

                Spacer(modifier = Modifier.height(16.dp))

                OutlinedTextField(
                    value = accountCode,
                    onValueChange = { 
                        accountCode = it.uppercase()
                        errorMessage = null
                    },
                    label = { Text("معرّف الحساب الذي سلّمته لك الإدارة") },
                    leadingIcon = { Icon(Icons.Default.Person, contentDescription = null, tint = BurgundyPrimary) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii, autoCorrect = false),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = BurgundyPrimary,
                        unfocusedBorderColor = BorderLight
                    )
                )

                if (activationMode) {
                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedTextField(
                        value = activationCode,
                        onValueChange = {
                            activationCode = it.uppercase()
                            errorMessage = null
                        },
                        label = { Text("رمز التفعيل من الإدارة (XXXX-XXXX-XXXX-XXXX)") },
                        leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null, tint = BurgundyPrimary) },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii, autoCorrect = false),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = BurgundyPrimary,
                            unfocusedBorderColor = BorderLight
                        )
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = passwordOrPin,
                    onValueChange = { 
                        passwordOrPin = it
                        errorMessage = null
                    },
                    label = { Text(if (activationMode) "كلمة المرور الجديدة (8 أحرف فأكثر)" else "كلمة المرور") },
                    leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null, tint = BurgundyPrimary) },
                    trailingIcon = {
                        IconButton(onClick = { isPinVisible = !isPinVisible }) {
                            Icon(
                                if (isPinVisible) Icons.Default.Close else Icons.Default.Info,
                                contentDescription = "تبديل الرؤية",
                                tint = TextSecondary
                            )
                        }
                    },
                    visualTransformation = if (isPinVisible) VisualTransformation.None else PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrect = false),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = BurgundyPrimary,
                        unfocusedBorderColor = BorderLight
                    )
                )

                if (activationMode) {
                    Spacer(modifier = Modifier.height(12.dp))
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
                        shape = RoundedCornerShape(10.dp),
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
                    errorMessage?.let { msg ->
                        Column {
                            Spacer(modifier = Modifier.height(12.dp))
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = StatusDangerBg,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(
                                    text = msg,
                                    color = StatusDanger,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Medium,
                                    modifier = Modifier.padding(10.dp),
                                    textAlign = TextAlign.Start,
                                    lineHeight = 16.sp
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(18.dp))

                Button(
                    onClick = {
                        val code = accountCode.trim()
                        val pw = passwordOrPin

                        if (code.isBlank() || pw.isBlank()) {
                            errorMessage = "يرجى إدخال معرّف الحساب وكلمة المرور"
                            return@Button
                        }
                        if (activationMode) {
                            if (activationCode.isBlank()) {
                                errorMessage = "يرجى إدخال رمز التفعيل الذي سلّمته لك الإدارة"
                                return@Button
                            }
                            if (pw.length < 8) {
                                errorMessage = "كلمة المرور يجب ألا تقل عن 8 أحرف"
                                return@Button
                            }
                            if (pw != confirmPassword) {
                                errorMessage = "كلمتا المرور غير متطابقتين"
                                return@Button
                            }
                        }

                        isLoading = true
                        errorMessage = null

                        coroutineScope.launch {
                            if (activationMode) {
                                val act = apiClient.activate(code, activationCode, pw)
                                if (act.isFailure) {
                                    isLoading = false
                                    errorMessage = act.exceptionOrNull()?.message ?: "تعذر إكمال التفعيل"
                                    return@launch
                                }
                            }
                            val signIn = apiClient.signIn(code, pw)
                            val tokens = signIn.getOrNull()
                            if (tokens == null) {
                                isLoading = false
                                errorMessage = signIn.exceptionOrNull()?.message ?: "تعذر تسجيل الدخول"
                                return@launch
                            }
                            val dash = apiClient.fetchDashboard(tokens.accessToken)
                            val payload = dash.getOrNull()
                            isLoading = false
                            if (payload == null) {
                                errorMessage = dash.exceptionOrNull()?.message ?: "تعذر جلب بيانات ولي الأمر"
                                return@launch
                            }
                            // لا تُحفظ كلمة المرور ولا رمز التفعيل في أي مكان
                            passwordOrPin = ""
                            confirmPassword = ""
                            activationCode = ""
                            onLoginSuccess(tokens, payload)
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = BurgundyPrimary),
                    enabled = !isLoading
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            color = Color.White,
                            strokeWidth = 2.dp,
                            modifier = Modifier.size(20.dp)
                        )
                    } else {
                        Text(
                            text = if (activationMode) "تفعيل الحساب والدخول" else "دخول إلى النظام",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
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
                        text = if (activationMode) "لدي حساب مفعّل — العودة لتسجيل الدخول" else "أول مرة أو نسيت كلمة المرور؟ فعّل بالرمز من الإدارة",
                        fontSize = 12.sp,
                        color = BurgundyPrimary
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Security Assurance Pill
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(horizontal = 12.dp)
        ) {
            Icon(
                Icons.Default.Lock,
                contentDescription = null,
                tint = BurgundyPrimary,
                modifier = Modifier.size(13.dp)
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = "اتصال آمن بخوادم مؤسسة العمرابي التعليمية",
                fontSize = 11.sp,
                color = TextSecondary
            )
        }
    }
}
