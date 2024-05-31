import Foundation

// * Create the `Todo` struct.
// * Ensure it has properties: id (UUID), title (String), and isCompleted (Bool).
struct Todo: Codable, CustomStringConvertible {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var description: String {
        return "\(isCompleted ? "✅" : "❌") \(title)"
    }

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false

    }

}

// Create the `Cache` protocol that defines the following method signatures:
//  `func save(todos: [Todo])`: Persists the given todos.
//  `func load() -> [Todo]?`: Retrieves and returns the saved todos, or nil if none exist.
protocol Cache {
    func save(todos: [Todo])
    func load() -> [Todo]?

}

// `FileSystemCache`: This implementation should utilize the file system 
// to persist and retrieve the list of todos. 
// Utilize Swift's `FileManager` to handle file operations.
final class JSONFileManagerCache: Cache {
    private let fileURL: URL 
    init(filename: String) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        fileURL = paths[0].appendingPathComponent(filename)
    }
    func save(todos: [Todo]) {
        do {
            let data = try JSONEncoder().encode(todos)
            try data.write(to: fileURL)
        }
        catch {
            print("❗ Error saving todos: \(error)")
        }
    }
    func load() -> [Todo]? {
        do {
            let data = try Data(contentsOf: fileURL)
            let todos = try JSONDecoder().decode([Todo].self, from: data)
            return todos
        }
        catch {
            print("❗ Error loading todos: \(error)")
            return nil
        }
    }

}

// `InMemoryCache`: : Keeps todos in an array or similar structure during the session. 
// This won't retain todos across different app launches, 
// but serves as a quick in-session cache.
final class InMemoryCache: Cache {
    private var cache: [Todo] = []
    func save(todos: [Todo]) {
        cache = todos
    }
    func load() -> [Todo]? {
        return cache
    }

}

// The `TodosManager` class should have:
// * A function `func listTodos()` to display all todos.
// * A function named `func addTodo(with title: String)` to insert a new todo.
// * A function named `func toggleCompletion(forTodoAtIndex index: Int)` 
//   to alter the completion status of a specific todo using its index.
// * A function named `func deleteTodo(atIndex index: Int)` to remove a todo using its index.
final class TodoManager {
    private var todos: [Todo] = []
    private var cache: Cache

    init(cache: Cache) {
        self.cache = cache
        loadTodos()
    }
    func listTodos() -> [Todo] {
        return todos
    }
    func addTodoWithTitle(_ title: String) {
        let todo = Todo(title: title)
        todos.append(todo)
        saveTodos()
    }
    func toggleCompletionForTodoAtIndex(_ index: Int){
        guard index >= 0 && index < todos.count else {return}
        todos[index].isCompleted.toggle()
        saveTodos()
    }
    private func saveTodos() {
        cache.save(todos: todos)
    }
    private func loadTodos() {
        if let loadedTodos = cache.load() {
            todos = loadedTodos
        }
    }
    func deleteTodoAtIndex(_ index: Int) {
        guard index >= 0 && index < todos.count else { return }
        todos.remove(at: index)
        saveTodos()
    }

}



// * The `App` class should have a `func run()` method, this method should perpetually 
//   await user input and execute commands.
//  * Implement a `Command` enum to specify user commands. Include cases 
//    such as `add`, `list`, `toggle`, `delete`, and `exit`.
//  * The enum should be nested inside the definition of the `App` class
final class App {
    enum Command: String {
        case add
        case list
        case toggle
        case delete
        case exit
        case invalid

        init(rawValue: String) {
            switch rawValue.lowercased() {
                case "add":
                self = .add
                case "list":
                self = .list
                case "toggle":
                self = .toggle
                case "delete":
                self = .delete
                case "exit":
                self = .exit
                default:
                self = .invalid
            }
        }
    
    }
    private let manager: TodoManager

    init (manager: TodoManager) {
        self.manager = manager
    }
    func run() {
        print("📝 Welcome to Todos CLI!!")

        while true{
            print("\nEnter a command: add, list, toggle, delete, exit")
            
            if let input = readLine(), !input.isEmpty {
                let command = Command(rawValue: input)
                switch command {
                    case.add:
                    handleAdd()
                    case .list:
                    handleList()
                    case .toggle:
                    handleToggle()
                    case .delete:
                    handleDelete()
                    case .exit:
                    print("See you!!")
                    return
                    case .invalid:
                    print("❗ Invalid command. Please try again.")
                }
            }
        }
    }
    private func handleAdd() {
        print("📌 Enter the title of the todo:")
        if let title = readLine(), !title.isEmpty {
            manager.addTodoWithTitle(title)
            print("📝 Todo added: \(title)")
        } else{
            print("Invalid Title.")
        }
    }
    private func handleList() {
        let todos = manager.listTodos()
        if todos.isEmpty {
            print("📝 No todos found.")
        } else {
            print("📝 Your todos:")
            for (index, todo) in todos.enumerated() {
                print("\(index) : \(todo)")
            }
        }
    }
    private func handleToggle() {
        print("📌 Enter the index of the todo to toggle:")
        if let input = readLine(), let index = Int(input), index >= 0 && index < manager.listTodos().count {
            manager.toggleCompletionForTodoAtIndex(index)
            print("📝 Toggled todo at index \(index).")
        } else {
            print("❗ Invalid index.")
        }

    }
    private func handleDelete() {
        print("📌 Enter the index of the todo to delete:")
        if let input = readLine(), let index = Int(input), index >= 0 && index < manager.listTodos().count {
            manager.deleteTodoAtIndex(index)
            print("🗑️ Deleted todo at index \(index).")
        }
        else {
            print("❗ Invalid index.")
        }
    }

}


// TODO: Write code to set up and run the app.
let cache = JSONFileManagerCache(filename: "todos.json")
let manager = TodoManager(cache: cache)
let app = App(manager: manager)
app.run()
