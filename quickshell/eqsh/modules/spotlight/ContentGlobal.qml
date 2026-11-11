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
        var total = root.answers ? root.answers.length : (root.count > 0 ? root.count : 0);
        if (total === 0) return;

        if (event.key === Qt.Key_Down) {
            currentIndex = (currentIndex + 1) % total;
            positionViewAtIndex(currentIndex, ListView.Contain);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            currentIndex = (currentIndex - 1 + total) % total;
            positionViewAtIndex(currentIndex, ListView.Contain);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            var targetIdx = (currentIndex >= 0 && currentIndex < total) ? currentIndex : 0;
            if (root.answers && root.answers[targetIdx] && typeof root.answers[targetIdx].clicked === "function") {
                root.answers[targetIdx].clicked();
                event.accepted = true;
            }
        }
    }

    model: ScriptModel {
        values: root.text == "" ? [] : root.answers
    }

    delegate: ContentItem {}
}
