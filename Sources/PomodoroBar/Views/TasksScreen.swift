import SwiftUI

/// Экран задач: прогресс дня, поле добавления, карточки с круглыми чекбоксами.
struct TasksScreen: View {
    @ObservedObject var store: TaskStore
    @State private var newTitle = ""

    private let tint = Phase.work.tint

    private var doneCount: Int { store.tasks.filter(\.isDone).count }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [tint.opacity(0.16), .clear], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                header
                inputField

                if store.tasks.isEmpty {
                    EmptyTasksHint()
                } else {
                    List {
                        ForEach(store.tasks) { task in
                            TaskCard(task: task, store: store, tint: tint)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        }
                        .onMove(perform: store.move)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                HStack {
                    Text("Клик по задаче делает её текущей, порядок меняется перетаскиванием.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if store.hasCompleted {
                        Button("Убрать выполненные", action: store.removeCompleted)
                            .buttonStyle(.borderless)
                    }
                }
            }
            .padding(28)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Задачи")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Spacer()
                if !store.tasks.isEmpty {
                    Text("\(doneCount) из \(store.tasks.count) выполнено")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            if !store.tasks.isEmpty {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(tint.opacity(0.15))
                        Capsule()
                            .fill(LinearGradient(colors: [Phase.work.accent, tint], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * Double(doneCount) / Double(max(1, store.tasks.count)))
                    }
                }
                .frame(height: 8)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: doneCount)
            }
        }
    }

    private var inputField: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(tint)
            TextField("Что нужно сделать?", text: $newTitle)
                .textFieldStyle(.plain)
                .font(.title3)
                .onSubmit(add)
            if !newTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                Button("Добавить", action: add)
                    .buttonStyle(.borderedProminent)
                    .tint(tint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
    }

    private func add() {
        store.add(newTitle)
        newTitle = ""
    }
}

private struct TaskCard: View {
    let task: TaskItem
    @ObservedObject var store: TaskStore
    var tint: Color

    private var isCurrent: Bool { store.currentTaskID == task.id }

    var body: some View {
        HStack(spacing: 12) {
            RoundCheckbox(isOn: task.isDone, tint: tint, size: 22) {
                store.setDone(task.id, !task.isDone)
            }

            Text(task.title)
                .font(.body.weight(isCurrent ? .semibold : .regular))
                .strikethrough(task.isDone, color: .secondary)
                .foregroundStyle(task.isDone ? .secondary : .primary)

            Spacer()

            if task.pomodoros > 0 {
                Text("🍅 \(task.pomodoros)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(tint.opacity(0.12)))
            }
            if isCurrent {
                Text("СЕЙЧАС")
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(tint.gradient))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isCurrent ? AnyShapeStyle(tint.opacity(0.10)) : AnyShapeStyle(BackgroundStyle().opacity(0.6)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isCurrent ? tint.opacity(0.5) : Color.primary.opacity(0.06), lineWidth: 1)
        )
        .opacity(task.isDone ? 0.65 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            if !task.isDone { store.currentTaskID = task.id }
        }
        .contextMenu {
            Button("Сделать текущей") { store.currentTaskID = task.id }
                .disabled(task.isDone)
            Button("Удалить", role: .destructive) { store.remove(task.id) }
        }
        .animation(.easeOut(duration: 0.2), value: isCurrent)
    }
}

/// Пустой список (ContentUnavailableView есть только с macOS 14).
private struct EmptyTasksHint: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("🍅")
                .font(.system(size: 56))
            Text("Пока нет задач")
                .font(.title3.weight(.semibold))
            Text("Напишите первую в поле выше и нажмите Return")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
