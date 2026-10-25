import SwiftUI

/// Экран задач: добавление, чекбоксы, выбор текущей, порядок перетаскиванием.
struct TasksScreen: View {
    @ObservedObject var store: TaskStore
    @State private var newTitle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Задачи")
                .font(.largeTitle.bold())

            HStack {
                TextField("Что нужно сделать?", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.large)
                    .onSubmit(add)
                Button(action: add) {
                    Label("Добавить", systemImage: "plus")
                }
                .controlSize(.large)
                .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if store.tasks.isEmpty {
                ContentUnavailableHint()
            } else {
                List {
                    ForEach(store.tasks) { task in
                        TaskRow(task: task, store: store)
                    }
                    .onMove(perform: store.move)
                }
                .listStyle(.inset(alternatesRowBackgrounds: false))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack {
                Text("Нажмите на задачу, чтобы сделать её текущей. Помодоро засчитываются текущей задаче.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if store.hasCompleted {
                    Button("Удалить выполненные", action: store.removeCompleted)
                }
            }
        }
        .padding(28)
    }

    private func add() {
        store.add(newTitle)
        newTitle = ""
    }
}

private struct TaskRow: View {
    let task: TaskItem
    @ObservedObject var store: TaskStore

    private var isCurrent: Bool { store.currentTaskID == task.id }

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { task.isDone },
                set: { store.setDone(task.id, $0) }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            Text(task.title)
                .strikethrough(task.isDone)
                .foregroundStyle(task.isDone ? .secondary : .primary)
                .fontWeight(isCurrent ? .semibold : .regular)

            Spacer()

            if task.pomodoros > 0 {
                Text("🍅 \(task.pomodoros)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if isCurrent {
                Image(systemName: "scope")
                    .foregroundStyle(Phase.work.tint)
                    .help("Текущая задача")
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !task.isDone { store.currentTaskID = task.id }
        }
        .contextMenu {
            Button("Сделать текущей") { store.currentTaskID = task.id }
                .disabled(task.isDone)
            Button("Удалить", role: .destructive) { store.remove(task.id) }
        }
    }
}

/// Пустой список (ContentUnavailableView есть только с macOS 14).
private struct ContentUnavailableHint: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checklist")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("Пока нет задач")
                .font(.title3.weight(.semibold))
            Text("Добавьте первую задачу в поле выше")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
