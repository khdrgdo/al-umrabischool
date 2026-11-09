package sd.alumrabi.parent.ui.screens

import androidx.compose.ui.graphics.Color
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Tone

/** (لون النص, لون الخلفية) حسب مستوى الأداء. */
internal fun toneColors(tone: Tone): Pair<Color, Color> = when (tone) {
    Tone.Great -> Positive to PositiveBg
    Tone.Good -> Teal to TealBg
    Tone.Okay -> Caution to CautionBg
    Tone.Low -> Negative to NegativeBg
}
