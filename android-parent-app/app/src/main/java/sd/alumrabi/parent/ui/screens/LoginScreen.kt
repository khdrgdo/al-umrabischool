package sd.alumrabi.parent.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
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
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(LavenderCanvas)
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Institutional Heraldic Emblem
        Surface(
            shape = RoundedCornerShape(18.dp),
            color = BurgundyPrimary,
            modifier = Modifier.size(76.dp),
            shadowElevation = 6.dp
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text(
                    text = "ع",
                    color = Color.White,
                    fontSize = 40.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "مدرسة العمرابي الثانوية",
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

        Spacer(modifier = Modifier.height(30.dp))

        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = SurfaceWhite),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(22.dp)
            ) {
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
                    shape = RoundedCornerShape(12.dp)
                )

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = passwordOrPin,
                    onValueChange = { 
                        passwordOrPin = it
                        errorMessage = null
                    },
                    label = { Text("كلمة المرور أو رمز التفعيل (PIN)") },
                    leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null, tint = BurgundyPrimary) },
                    visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
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

                Spacer(modifier = Modifier.height(20.dp))

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

                                    val childrenResult = apiClient.fetchChildrenForGuardian(guardian.id)
                                    val children = childrenResult.getOrDefault(emptyList())

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
                    shape = RoundedCornerShape(12.dp),
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
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "تجربة حساب معتمد:",
                        fontSize = 11.sp,
                        color = TextSecondary
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    TextButton(
                        onClick = {
                            accountCode = "PAR-10101"
                            passwordOrPin = "449210"
                            errorMessage = null
                        },
                        contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = "PAR-10101 (د. عبدالله)",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = BurgundyPrimary
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Institutional Security Notice
        Card(
            shape = RoundedCornerShape(12.dp),
            colors = CardDefaults.cardColors(containerColor = BurgundyContainer.copy(alpha = 0.5f)),
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(
                modifier = Modifier.padding(12.dp),
                verticalAlignment = Alignment.Top
            ) {
                Icon(
                    Icons.Default.Info,
                    contentDescription = null,
                    tint = BurgundyPrimary,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "تنويه أمني: تُنشأ حسابات أولياء الأمور وتُفعّل حصراً عبر إدارة المدرسة. في حال نسيان كلمة المرور، يرجى مراجعة إدارة المدرسة شخصياً لطلب رمز تفعيل جديد.",
                    fontSize = 11.sp,
                    color = BurgundyDark,
                    lineHeight = 16.sp
                )
            }
        }
    }
}
