package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.data.ai.AiAssistantService
import sd.alumrabi.parent.data.model.*
import sd.alumrabi.parent.ui.components.OmrabiTopBar
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt
import java.util.UUID

private val suggestions = listOf("درجاتي", "الحضور", "الرسوم", "الإعلانات", "المواعيد القادمة")

@Composable
fun AiAssistantScreen(
    guardian: GuardianInfo,
    activeChild: LinkedChild?,
    announcements: List<AnnouncementItem>,
    events: List<CalendarEventItem>,
    onBack: () -> Unit
) {
    val service = remember { AiAssistantService() }
    val messages = remember { mutableStateListOf(service.welcome(guardian, activeChild)) }
    var input by remember { mutableStateOf("") }
    val listState = rememberLazyListState()

    LaunchedEffect(messages.size) {
        listState.animateScrollToItem(messages.lastIndex)
    }

    fun send(text: String) {
        val clean = text.trim()
        if (clean.isEmpty()) return
        messages.add(AiChatMessage(UUID.randomUUID().toString(), MessageSender.USER, clean))
        messages.add(service.generateResponse(clean, guardian, activeChild, announcements, events))
        input = ""
    }

    Scaffold(
        topBar = {
            OmrabiTopBar(
                title = "المساعد",
                subtitle = activeChild?.let { Fmt.shortName(it.fullName) },
                onBack = onBack
            )
        },
        containerColor = Canvas
    ) { padding ->
        Column(
            Modifier
                .padding(padding)
                .imePadding()
                .navigationBarsPadding()
        ) {
            LazyColumn(
                state = listState,
                modifier = Modifier.weight(1f),
                contentPadding = PaddingValues(horizontal = Space.gutter, vertical = Space.md),
                verticalArrangement = Arrangement.spacedBy(Space.sm)
            ) {
                items(messages, key = { it.id }) { m ->
                    val mine = m.sender == MessageSender.USER
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Start) {
                        if (!mine) Spacer(Modifier.width(Space.xxl))
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (mine) Crimson600 else Paper,
                            border = if (mine) null else BorderStroke(1.dp, Line),
                            modifier = Modifier.weight(1f, fill = false)
                        ) {
                            Text(
                                m.text,
                                style = MaterialTheme.typography.bodyMedium,
                                color = if (mine) OnBrand else Ink900,
                                modifier = Modifier.padding(horizontal = Space.md, vertical = Space.md)
                            )
                        }
                        if (mine) Spacer(Modifier.width(Space.xxl))
                    }
                }
            }

            LazyRow(
                contentPadding = PaddingValues(horizontal = Space.gutter),
                horizontalArrangement = Arrangement.spacedBy(Space.sm)
            ) {
                items(suggestions) { s ->
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = Paper,
                        border = BorderStroke(1.dp, LineStrong),
                        modifier = Modifier.clickable { send(s) }
                    ) {
                        Text(
                            s,
                            style = MaterialTheme.typography.labelLarge,
                            color = Ink700,
                            modifier = Modifier
                                .heightIn(min = 40.dp)
                                .padding(horizontal = Space.md, vertical = Space.sm)
                                .wrapContentHeight(Alignment.CenterVertically)
                        )
                    }
                }
            }

            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Space.gutter, vertical = Space.md),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = input,
                    onValueChange = { input = it },
                    modifier = Modifier.weight(1f),
                    placeholder = { Text("اكتب سؤالك", color = Ink500) },
                    shape = RoundedCornerShape(8.dp),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                    keyboardActions = KeyboardActions(onSend = { send(input) }),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Crimson600,
                        unfocusedBorderColor = LineStrong,
                        focusedContainerColor = Paper,
                        unfocusedContainerColor = Paper
                    )
                )
                Spacer(Modifier.width(Space.sm))
                FilledIconButton(
                    onClick = { send(input) },
                    enabled = input.isNotBlank(),
                    modifier = Modifier.size(48.dp),
                    colors = IconButtonDefaults.filledIconButtonColors(
                        containerColor = Crimson600,
                        contentColor = OnBrand
                    )
                ) {
                    Icon(Icons.AutoMirrored.Filled.Send, contentDescription = "إرسال")
                }
            }
        }
    }
}
