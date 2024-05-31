import XCTest
import Foundation


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

protocol Cache {
    func save(todos: [Todo])
    func load() -> [Todo]?
}

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

final class InMemoryCache: Cache {
    private var cache: [Todo] = []
    func save(todos: [Todo]) {
        cache = todos
    }
    func load() -> [Todo]? {
        return cache
    }
}

protocol TodoManagerProtocol {
    func listTodos() -> [Todo]
    func addTodoWithTitle(_ title: String)
    func toggleCompletionForTodoAtIndex(_ index: Int)
    func deleteTodoAtIndex(_ index: Int)
}

final class TodoManager: TodoManagerProtocol {
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

    private let manager: TodoManagerProtocol

    init(manager: TodoManagerProtocol) {
        self.manager = manager
    }

    func run() {
        print("📝 Welcome to Todos CLI!!")

        while true {
            print("\nEnter a command: add, list, toggle, delete, exit")
            if let input = readLine(), !input.isEmpty {
                let command = Command(rawValue: input)
                switch command {
                case .add:
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
        } else {
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
        } else {
            print("❗ Invalid index.")
        }
    }
}

// Testing
final class AppTests: XCTestCase {
    
    var app: App!
    var mockManager: MockTodoManager!
    
    override func setUp() {
        super.setUp()
        mockManager = MockTodoManager()
        app = App(manager: mockManager)
    }
    
    func testAddTodoCommand() {
        // Simulate user input for adding a todo
        mockManager.inputBuffer = "add\nBuy groceries\nexit\n"
        app.run()
        XCTAssertTrue(mockManager.didAddTodo)
        XCTAssertEqual(mockManager.lastAddedTitle, "Buy groceries")
    }
    
    func testListTodosCommandWithEmptyList() {
        // Simulate user input for listing todos
        mockManager.inputBuffer = "list\nexit\n"
        app.run()
        XCTAssertTrue(mockManager.outputBuffer.contains("No todos found."))
    }
    
    func testListTodosCommandWithExistingTodos() {
        // Prepopulate mock manager with todos
        mockManager.stubbedTodos = [Todo(title: "Buy groceries"), Todo(title: "Walk the dog")]
        // Simulate user input for listing todos
        mockManager.inputBuffer = "list\nexit\n"
        app.run()
        XCTAssertTrue(mockManager.outputBuffer.contains("Your todos:"))
        XCTAssertTrue(mockManager.outputBuffer.contains("0 : ❌ Buy groceries"))
        XCTAssertTrue(mockManager.outputBuffer.contains("1 : ❌ Walk the dog"))
    }
    
    
}

// MockTodoManager to simulate TodoManager for testing purposes
class MockTodoManager: TodoManagerProtocol {
    var didAddTodo = false
    var lastAddedTitle: String?
    var stubbedTodos: [Todo] = []
    var inputBuffer: String = ""
    var outputBuffer: String = ""

    func addTodoWithTitle(_ title: String) {
        didAddTodo = true
        lastAddedTitle = title
    }
    
    func listTodos() -> [Todo] {
        return stubbedTodos
    }
    
    func toggleCompletionForTodoAtIndex(_ index: Int) {
        
    }
    
    func deleteTodoAtIndex(_ index: Int) {
        
    }
}
