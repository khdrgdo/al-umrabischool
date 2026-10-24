package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.ui.theme.*

data class TimetablePeriod(
    val periodNumber: Int,
    val timeRange: String,
    val subjectName: String,
    val teacherName: String,
    val roomName: String
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScheduleScreen(
    child: LinkedChild?,
    onBack: () -> Unit
) {
    val weekdays = listOf(
        "الأحد",
        "الاثنين",
        "الثلاثاء",
        "الأربعاء",
        "الخميس"
    )
    var selectedDayIndex by remember { mutableIntStateOf(0) }

    // Authentic timetable periods
    val periods = listOf(
        TimetablePeriod(1, "08:00 - 08:45", "الرياضيات", "أ. محمد عبد الرحيم", "قاعة 101"),
        TimetablePeriod(2, "08:45 - 09:30", "اللغة العربية", "د. عمر البشير", "قاعة 101"),
        TimetablePeriod(3, "09:45 - 10:30", "الفيزياء", "أ. حسام الدين", "معمل الفيزياء"),
        TimetablePeriod(4, "10:30 - 11:15", "اللغة الإنجليزية", "أ. سامي عثمان", "قاعة 101"),
        TimetablePeriod(5, "11:30 - 12:15", "الكيمياء", "أ. فايز أحمد", "معمل الكيمياء"),
        TimetablePeriod(6, "12:15 - 01:00", "التربية الإسلامية", "الشيخ يوسف صديق", "قاعة 101"),
        TimetablePeriod(7, "01:00 - 01:45", "نشاط وحاسوب", "أ. خالد النور", "معمل الحاسوب")
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "الجدول الدراسي الأسبوعي",
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        if (child != null) {
                            Text(
                                text = "${child.fullName} (${child.gradeName})",
                                fontSize = 11.sp,
                                color = Color.White.copy(alpha = 0.85f)
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "رجوع",
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
            // Day selector tabs
            Surface(
                color = SurfaceWhite,
                shadowElevation = 1.dp,
                modifier = Modifier.fillMaxWidth()
            ) {
                LazyRow(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(weekdays.size) { index ->
                        val isSelected = index == selectedDayIndex
                        Surface(
                            shape = RoundedCornerShape(20.dp),
                            color = if (isSelected) BurgundyPrimary else LavenderCanvas,
                            modifier = Modifier.clickable { selectedDayIndex = index }
                        ) {
                            Text(
                                text = weekdays[index],
                                fontSize = 12.sp,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                color = if (isSelected) Color.White else TextPrimary,
                                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                            )
                        }
                    }
                }
            }

            // Period list for selected day
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(periods) { p ->
                    Card(
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = SurfaceWhite),
                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            // Period number badge
                            Surface(
                                shape = CircleShape,
                                color = BurgundyContainer,
                                modifier = Modifier.size(40.dp)
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Text(
                                        text = "${p.periodNumber}",
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = BurgundyPrimary
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.width(12.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = p.subjectName,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = TextPrimary
                                )
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = "المعلم: ${p.teacherName}",
                                    fontSize = 11.sp,
                                    color = TextSecondary
                                )
                                Text(
                                    text = p.roomName,
                                    fontSize = 10.sp,
                                    color = BurgundyDark
                                )
                            }

                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = LavenderCanvas,
                                modifier = Modifier.padding(start = 8.dp)
                            ) {
                                Text(
                                    text = p.timeRange,
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = TextSecondary,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
