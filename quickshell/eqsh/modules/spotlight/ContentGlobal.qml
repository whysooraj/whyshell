import Quickshell
import QtQuick
import QtQuick.Layouts
import qs
import qs.config
import qs.ui.controls.advanced
import qs.ui.controls.auxiliary
import qs.ui.controls.primitives

ListView {
    id: root
    spacing: 4

    required property string text
    required property list<var> answers
    required property string textColor

    currentIndex: 0
    highlightFollowsCurrentItem: true
    keyNavigationWraps: true

    onAnswersChanged: {
        currentIndex = 0;
    }

    onTextChanged: {
        currentIndex = 0;
    }

    function keyPressed(event) {
        if (!event) return;
        var count = model && model.values ? model.values.length : 0;
        if (count === 0) return;

        if (event.key === Qt.Key_Down) {
            currentIndex = (currentIndex + 1) % count;
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            currentIndex = (currentIndex - 1 + count) % count;
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            var targetIdx = currentIndex >= 0 && currentIndex < count ? currentIndex : 0;
            var item = model.values[targetIdx];
            if (item && typeof item.clicked === "function") {
                item.clicked();
                event.accepted = true;
            }
        }
    }

    model: ScriptModel {
        values: root.text == "" ? [] : root.answers
    }

    delegate: ContentItem {}
}
