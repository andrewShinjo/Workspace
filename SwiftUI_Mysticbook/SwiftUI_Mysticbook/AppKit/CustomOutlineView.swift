import AppKit

class CustomOutlineView: NSOutlineView {
    override func mouseDown(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)

        let row = self.row(at: point)
        if row != -1,
           let cellView = self.view(atColumn: 0, row: row, makeIfNecessary: false) as? NSTableCellView,
           cellView.viewWithTag(100) != nil {
            let cellPoint = cellView.convert(point, from: self)
            if cellPoint.x < 24,
               let item = self.item(atRow: row),
               let node = item as? OutlinerNode,
               !node.children.isEmpty {
                if self.isItemExpanded(item) {
                    self.collapseItem(item)
                } else {
                    self.expandItem(item)
                }
                return
            }
        }

        super.mouseDown(with: event)
    }
}
