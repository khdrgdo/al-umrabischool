package sd.alumrabi.parent.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import sd.alumrabi.parent.data.ai.AiAssistantService
import sd.alumrabi.parent.data.model.*
import sd.alumrabi.parent.ui.theme.*
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AiAssistantScreen(
    guardian: GuardianInfo,
    activeChild: LinkedChild?,
    announcements: List<AnnouncementItem> = emptyList(),
    events: List<CalendarEventItem> = emptyList(),
    onBack: () -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val aiService = remember { AiAssistantService() }
    val listState = rememberLazyListState()

    var inputText by remember { mutableStateOf("") }
    var isThinking by remember { mutableStateOf(false) }

    val messages = remember {
        mutableStateListOf(
            AiChatMessage(
                id = "init-1",
                sender = MessageSender.ASSISTANT,
                text = "مرحباً بك يا ${guardian.fullName} في **مساعد العمرابي الذكي** 🎓.\n\nأنا هنا لمساعدتك في المتابعة التربوية الدقيقة لابنك **${activeChild?.fullName ?: "الطالب"}** (${activeChild?.gradeName ?: ""}).\n\nيمكنك الاستفسار عن جدول الحصص، رصد الدرجات، الحضور والانضباط، الموقف المالي للرسوم، أو مواعيد الامتحانات والفعاليات."
            )
        )
    }

    val quickChips = listOf(
        "📅 ما هي حصص ابني اليوم؟",
        "📊 ملخص الدرجات الأكاديمية",
        "📝 كشف الحضور والغياب",
        "💳 موقف سداد الرسوم الدراسية",
        "🗓️ مواعيد الامتحانات القادمة"
    )

    fun sendMessage(query: String) {
        if (query.isBlank() || isThinking) return
        val userMsg = AiChatMessage(
            id = UUID.randomUUID().toString(),
            sender = MessageSender.USER,
            text = query
        )
        messages.add(userMsg)
        inputText = ""
        isThinking = true

        coroutineScope.launch {
            listState.animateScrollToItem(messages.size - 1)
            val response = aiService.generateResponse(
                userQuery = query,
                guardian = guardian,
                activeChild = activeChild,
                announcements = announcements,
                events = events
            )
            isThinking = false
            messages.add(response)
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "مساعد العمرابي الذكي",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Surface(
                                shape = RoundedCornerShape(6.dp),
                                color = Color(0xFFC5A059),
                                modifier = Modifier.padding(top = 1.dp)
                            ) {
                                Text(
                                    text = "AI آمن",
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                )
                            }
                        }
                        Text(
                            text = "النطاق الأكاديمي: ${activeChild?.fullName ?: "طالب غير محدد"}",
                            fontSize = 11.sp,
                            color = Color.White.copy(alpha = 0.85f)
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            Icons.Default.ArrowBack,
                            contentDescription = "الرجوع",
                            tint = Color.White
                        )
                    }
                },
                actions = {
                    IconButton(onClick = {
                        messages.clear()
                        messages.add(
                            AiChatMessage(
                                id = UUID.randomUUID().toString(),
                                sender = MessageSender.ASSISTANT,
                                text = "تمت إعادة ضبط المحادثة. كيف يمكنني مساعدتك بخصوص الطالب ${activeChild?.fullName}؟"
                            )
                        )
                    }) {
                        Icon(
                            Icons.Default.Refresh,
                            contentDescription = "إعادة ضبط",
                            tint = Color.White
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = BurgundyPrimary)
            )
        },
        containerColor = LavenderCanvas
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Security & Privacy Gating Strip (Anti-AI Aesthetics: Clean, quiet, reassuring)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFFF1F1F8))
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.Lock,
                    contentDescription = null,
                    tint = BurgundyPrimary,
                    modifier = Modifier.size(14.dp)
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = "محادثة مشفرة وخاصة: لا تطلع على أي بيانات خارج نطاق أبنائك المعتمدين.",
                    fontSize = 11.sp,
                    color = TextSecondary
                )
            }

            // Chat Messages List
            LazyColumn(
                state = listState,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(messages, key = { it.id }) { msg ->
                    ChatMessageBubble(message = msg)
                }

                if (isThinking) {
                    item {
                        ThinkingBubble()
                    }
                }
            }

            // Quick Prompt Chips
            LazyRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(quickChips) { chip ->
                    Surface(
                        shape = RoundedCornerShape(20.dp),
                        color = SurfaceWhite,
                        shadowElevation = 1.dp,
                        modifier = Modifier.clickable { sendMessage(chip) }
                    ) {
                        Text(
                            text = chip,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            color = BurgundyPrimary,
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp)
                        )
                    }
                }
            }

            // Bottom Input Bar
            Surface(
                color = SurfaceWhite,
                shadowElevation = 6.dp,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = inputText,
                        onValueChange = { inputText = it },
                        placeholder = {
                            Text(
                                "اطرح سؤالك هنا (مثال: هل غاب ابني هذا الأسبوع؟)...",
                                fontSize = 13.sp,
                                color = TextSecondary
                            )
                        },
                        modifier = Modifier
                            .weight(1f)
                            .padding(end = 8.dp),
                        shape = RoundedCornerShape(24.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = BurgundyPrimary,
                            unfocusedBorderColor = BorderLight,
                            focusedContainerColor = LavenderCanvas,
                            unfocusedContainerColor = LavenderCanvas
                        ),
                        maxLines = 3
                    )

                    IconButton(
                        onClick = { sendMessage(inputText) },
                        enabled = inputText.isNotBlank() && !isThinking,
                        modifier = Modifier
                            .size(44.dp)
                            .clip(CircleShape)
                            .background(if (inputText.isNotBlank()) BurgundyPrimary else Color(0xFFD1D5DB))
                    ) {
                        Icon(
                            Icons.Default.Send,
                            contentDescription = "إرسال",
                            tint = Color.White,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ChatMessageBubble(message: AiChatMessage) {
    val isUser = message.sender == MessageSender.USER

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isUser) Arrangement.Start else Arrangement.End
    ) {
        if (!isUser) {
            Surface(
                shape = CircleShape,
                color = BurgundyPrimary,
                modifier = Modifier
                    .size(32.dp)
                    .align(Alignment.Top)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text("ع", color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold)
                }
            }
            Spacer(modifier = Modifier.width(8.dp))
        }

        Surface(
            shape = RoundedCornerShape(
                topStart = 16.dp,
                topEnd = 16.dp,
                bottomStart = if (isUser) 4.dp else 16.dp,
                bottomEnd = if (isUser) 16.dp else 4.dp
            ),
            color = if (isUser) BurgundyPrimary else SurfaceWhite,
            shadowElevation = 1.dp,
            modifier = Modifier.widthIn(max = 300.dp)
        ) {
            Text(
                text = message.text,
                fontSize = 13.5.sp,
                lineHeight = 20.sp,
                color = if (isUser) Color.White else TextPrimary,
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp)
            )
        }

        if (isUser) {
            Spacer(modifier = Modifier.width(8.dp))
            Surface(
                shape = CircleShape,
                color = Color(0xFFE2E8F0),
                modifier = Modifier
                    .size(32.dp)
                    .align(Alignment.Top)
            ) {
                Icon(
                    Icons.Default.Person,
                    contentDescription = null,
                    tint = TextSecondary,
                    modifier = Modifier.padding(6.dp)
                )
            }
        }
    }
}

@Composable
fun ThinkingBubble() {
    val infiniteTransition = rememberInfiniteTransition(label = "thinking")
    val alpha by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(600, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "dots"
    )

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.End
    ) {
        Surface(
            shape = CircleShape,
            color = BurgundyPrimary,
            modifier = Modifier.size(32.dp)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text("ع", color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold)
            }
        }
        Spacer(modifier = Modifier.width(8.dp))
        Surface(
            shape = RoundedCornerShape(14.dp),
            color = SurfaceWhite,
            shadowElevation = 1.dp
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "جاري قراءة السجلات وصياغة الرد...",
                    fontSize = 12.sp,
                    color = TextSecondary,
                    modifier = Modifier.padding(end = 8.dp)
                )
                CircularProgressIndicator(
                    strokeWidth = 2.dp,
                    color = BurgundyPrimary,
                    modifier = Modifier.size(14.dp)
                )
            }
        }
    }
}
