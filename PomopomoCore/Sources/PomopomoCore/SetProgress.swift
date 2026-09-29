/// How far today's current Set has got, and how many Pomodoros were Completed today.
public struct SetProgress: Hashable, Sendable {
    /// Which Set of the Day this is, counting from 1.
    public let number: Int
    /// Completed Pomodoros in this Set so far.
    public let completed: Int
    /// How many Completed Pomodoros make a Set.
    public let size: Int
    public let completedToday: Int

    public init(number: Int, completed: Int, size: Int, completedToday: Int) {
        self.number = number
        self.completed = completed
        self.size = size
        self.completedToday = completedToday
    }
}
