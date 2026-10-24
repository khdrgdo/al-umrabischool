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
import sd.alumrabi.parent.data.api.ParentApiClient
import sd.alumrabi.parent.data.model.GuardianInfo
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.ui.theme.*

@Composable
fun LoginScreen(
    onLoginSuccess: (guardian: GuardianInfo, children: List<LinkedChild>) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val apiClient = remember { ParentApiClient() }

    var accountCode by remember { mutableStateOf("") }
    var passwordOrPin by remember { mutableStateOf("") }
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
            text = "مدرسة العمرابي الثانوية بنين",
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
            color = BurgundyPrimary
        )

        Text(
            text = "بوابة أولياء الأمور والمتابعة الأكاديمية الرسمية",
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
                    label = { Text("معرّف الحساب (مثال: PAR-10101)") },
                    leadingIcon = { Icon(Icons.Default.Person, contentDescription = null, tint = BurgundyPrimary) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = BurgundyPrimary,
                        unfocusedBorderColor = BorderLight
                    )
                )

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = passwordOrPin,
                    onValueChange = { 
                        passwordOrPin = it
                        errorMessage = null
                    },
                    label = { Text("كلمة المرور أو رمز PIN") },
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
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = BurgundyPrimary,
                        unfocusedBorderColor = BorderLight
                    )
                )

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
                        val trimmedCode = accountCode.trim()
                        val trimmedPin = passwordOrPin.trim()

                        if (trimmedCode.isBlank() || trimmedPin.isBlank()) {
                            errorMessage = "يرجى إدخال معرّف الحساب ورمز المرور"
                            return@Button
                        }

                        isLoading = true
                        errorMessage = null

                        coroutineScope.launch {
                            val loginResult = apiClient.login(trimmedCode, trimmedPin)
                            loginResult.onSuccess { response ->
                                if (response.success) {
                                    val guardian = GuardianInfo(
                                        id = response.guardianId ?: "g-${System.currentTimeMillis()}",
                                        accountCode = response.accountCode ?: trimmedCode,
                                        fullName = response.fullName ?: "ولي الأمر",
                                        phone = "",
                                        status = response.status ?: "active"
                                    )

                                    val portalResult = apiClient.fetchPortalData(guardian.id, guardian.accountCode ?: trimmedCode)
                                    val children = portalResult.getOrNull()?.children ?: apiClient.getSeedChildrenForGuardian(guardian.id)

                                    isLoading = false
                                    onLoginSuccess(guardian, children)
                                } else {
                                    isLoading = false
                                    errorMessage = response.message ?: "بيانات الدخول غير صحيحة. يرجى التأكد من المعرّف أو مراجعة إدارة المدرسة."
                                }
                            }.onFailure { err ->
                                isLoading = false
                                errorMessage = "تعذر الاتصال بالخادم حالياً. يرجى التأكد من اتصال الإنترنت والمحاولة لاحقاً."
                            }
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
                            text = "دخول إلى النظام",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
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
                text = "اتصال آمن ومشفر عبر خوادم مدرسة العمرابي الرسمية",
                fontSize = 11.sp,
                color = TextSecondary
            )
        }

        Spacer(modifier = Modifier.height(18.dp))

        // Quick Testing Chip (For physical device testing by school leadership)
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = BurgundyContainer,
            border = androidx.compose.foundation.BorderStroke(1.dp, BurgundyLight.copy(alpha = 0.3f)),
            modifier = Modifier.clickable {
                accountCode = "PAR-10101"
                passwordOrPin = "449210"
                errorMessage = null
            }
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "تجربة سريعة: د. عبد الله (PAR-10101)",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium,
                    color = BurgundyPrimary
                )
            }
        }
    }
}
