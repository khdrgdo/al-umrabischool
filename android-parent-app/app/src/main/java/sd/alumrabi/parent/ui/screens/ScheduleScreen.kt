package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.data.model.ScheduleEntry
import sd.alumrabi.parent.ui.theme.*

private data class SchoolWeekday(val key: String, val label: String, val shortKey: String)
private val schoolWeekdays = listOf(
    SchoolWeekday("sunday", "الأحد", "sun"),
    SchoolWeekday("monday", "الاثنين", "mon"),
    SchoolWeekday("tuesday", "الثلاثاء", "tue"),
    SchoolWeekday("wednesday", "الأربعاء", "wed"),
    SchoolWeekday("thursday", "الخميس", "thu")
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScheduleScreen(child: LinkedChild?, onBack: () -> Unit) {
    var selectedDayIndex by remember { mutableIntStateOf(0) }
    val selectedDay = schoolWeekdays[selectedDayIndex]
    val dayEntries = child?.schedule.orEmpty()
        .filter { entry ->
            val day = entry.dayOfWeek.trim().lowercase()
            day == selectedDay.key || day == selectedDay.shortKey || day == selectedDay.label
        }
        .sortedBy { it.periodNumber }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("الجدول الدراسي", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Color.White)
                        if (child != null) Text("${child.fullName} (${child.gradeName})", fontSize = 11.sp, color = Color.White.copy(alpha = 0.85f))
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "رجوع", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = BurgundyPrimary)
            )
        },
        containerColor = LavenderCanvas
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            Surface(color = SurfaceWhite, shadowElevation = 1.dp, modifier = Modifier.fillMaxWidth()) {
                LazyRow(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(schoolWeekdays) { day ->
                        val index = schoolWeekdays.indexOf(day)
                        val selected = index == selectedDayIndex
                        Surface(
                            shape = RoundedCornerShape(20.dp),
                            color = if (selected) BurgundyPrimary else LavenderCanvas,
                            modifier = Modifier.clickable { selectedDayIndex = index }
                        ) {
                            Text(
                                day.label,
                                fontSize = 12.sp,
                                fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
                                color = if (selected) Color.White else TextPrimary,
                                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                            )
                        }
                    }
                }
            }

            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
                contentPadding = PaddingValues(bottom = 20.dp)
            ) {
                if (child == null) {
                    item { ScheduleEmptyState("اختر أحد الأبناء أولاً لعرض جدوله الدراسي.") }
                } else if (dayEntries.isEmpty()) {
                    item { ScheduleEmptyState("لم يُنشر جدول دراسي لهذا اليوم بعد. ستظهر الحصص هنا بعد اعتمادها من إدارة المؤسسة.") }
                } else {
                    items(dayEntries, key = { "${it.dayOfWeek}-${it.periodNumber}-${it.subjectName}" }) { entry ->
                        SchedulePeriodCard(entry)
                    }
                }
            }
        }
    }
}

@Composable
private fun SchedulePeriodCard(entry: ScheduleEntry) {
    Card(
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = SurfaceWhite),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(modifier = Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
            Surface(shape = CircleShape, color = BurgundyContainer, modifier = Modifier.size(40.dp)) {
                Box(contentAlignment = Alignment.Center) {
                    Text(entry.periodNumber.toString(), fontSize = 14.sp, fontWeight = FontWeight.Bold, color = BurgundyPrimary)
                }
            }
            Spacer(Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(entry.subjectName, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                entry.teacherName?.takeIf { it.isNotBlank() }?.let { Text("المعلم: $it", fontSize = 11.sp, color = TextSecondary) }
                entry.roomName?.takeIf { it.isNotBlank() }?.let { Text(it, fontSize = 10.sp, color = BurgundyDark) }
            }
            val timeRange = listOf(entry.startsAt, entry.endsAt).filter { it.isNotBlank() }.joinToString(" - ")
            if (timeRange.isNotBlank()) {
                Surface(shape = RoundedCornerShape(8.dp), color = LavenderCanvas, modifier = Modifier.padding(start = 8.dp)) {
                    Text(timeRange, fontSize = 10.sp, fontWeight = FontWeight.Medium, color = TextSecondary, modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp))
                }
            }
        }
    }
}

@Composable
private fun ScheduleEmptyState(message: String) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = SurfaceWhite,
        border = androidx.compose.foundation.BorderStroke(1.dp, BorderLight),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 22.dp, vertical = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Icon(Icons.Default.CalendarMonth, contentDescription = null, tint = BurgundyPrimary, modifier = Modifier.size(30.dp))
            Text("الجدول غير متاح", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
            Text(message, fontSize = 12.sp, color = TextSecondary, lineHeight = 19.sp)
        }
    }
}
