// 兼容 shim：UOS 的 Qt 6.8 把 QListView::eventFilter / mousePressEvent 导出成符号，
// Arch 的 Qt 6.12 已把它们并进 QAbstractItemView（由私有实现处理）。
// 这里补上同名符号并转发到基类非虚实现，保持语义等价。
#include <QAbstractItemView>
#include <QListView>
#include <QMouseEvent>
#include <QObject>

namespace {
struct Access : QAbstractItemView {
    static bool ev(QAbstractItemView *self, QObject *o, QEvent *e)
    { return static_cast<Access *>(self)->Access::eventFilter(o, e); }   // 限定调用 = 非虚
    static void mp(QAbstractItemView *self, QMouseEvent *e)
    { static_cast<Access *>(self)->Access::mousePressEvent(e); }         // 限定调用 = 非虚
};
}

extern "C" {
bool qlv_eventFilter(void *, QObject *, QEvent *)
    __asm__("_ZN9QListView11eventFilterEP7QObjectP6QEvent");
void qlv_mousePressEvent(void *, QMouseEvent *)
    __asm__("_ZN9QListView15mousePressEventEP11QMouseEvent");

bool qlv_eventFilter(void *self, QObject *o, QEvent *e)
{ return Access::ev(static_cast<QAbstractItemView *>(static_cast<QListView *>(self)), o, e); }

void qlv_mousePressEvent(void *self, QMouseEvent *e)
{ Access::mp(static_cast<QAbstractItemView *>(static_cast<QListView *>(self)), e); }
}
