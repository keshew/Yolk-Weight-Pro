import SwiftUI
import Combine

struct Eggies: Identifiable, Codable, Equatable {
    let id: UUID
    var weight: Int
    var batch: String?
    var note: String?
    var date: Date
    
    enum Classification: String, Codable {
        case S, M, L, XL
    }
    
    var classification: Classification {
        switch weight {
        case ..<53: return .S
        case 53...62: return .M
        case 63...72: return .L
        default: return .XL
        }
    }
}

class EggStorage: ObservableObject {
    @Published var eggs: [Eggies] = []
    
    private let eggsKey = "EggWeightPro_Eggs"
    
    init() {
        load()
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: eggsKey) else {
            eggs = []
            return
        }
        if let savedEggs = try? JSONDecoder().decode([Eggies].self, from: data) {
            eggs = savedEggs.sorted(by: { $0.date > $1.date })
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(eggs) {
            UserDefaults.standard.set(encoded, forKey: eggsKey)
        }
    }
    
    func addEgg(weight: Int, batch: String?, note: String?, date: Date = Date()) {
        let newEgg = Eggies(id: UUID(), weight: weight, batch: batch, note: note, date: date)
        eggs.insert(newEgg, at: 0)
        save()
    }
    
    func deleteEgg(at offsets: IndexSet) {
        eggs.remove(atOffsets: offsets)
        save()
    }
}

class EggsViewModel: ObservableObject {
    @Published var weightInput: String = ""
    @Published var batchInput: String = ""
    @Published var noteInput: String = ""
    @Published var dateInput: Date = Date()
    @Published var useSmartScale: Bool = false
    
    @Published var classificationBadgeColor: Color = .gray
    
    @ObservedObject private(set) var storage = EggStorage()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        $weightInput
            .map { weightStr -> Color in
                guard let weight = Int(weightStr), weight > 0 else {
                    return .gray
                }
                switch weight {
                case ..<53: return .yellow.opacity(0.7)
                case 53...62: return .yellow
                case 63...72: return .yolkYellow
                default: return .yellow.opacity(0.9)
                }
            }
            .assign(to: \.classificationBadgeColor, on: self)
            .store(in: &cancellables)
    }
    
    func addEgg() {
        guard let weight = Int(weightInput), weight > 0 else { return }
        let batch = batchInput.isEmpty ? nil : batchInput
        let note = noteInput.isEmpty ? nil : noteInput
        storage.addEgg(weight: weight, batch: batch, note: note, date: dateInput)
        
        clearInputs()
    }
    
    func clearInputs() {
        weightInput = ""
        batchInput = ""
        noteInput = ""
        dateInput = Date()
    }
    
    func deleteEgg(at offsets: IndexSet) {
        storage.deleteEgg(at: offsets)
    }
}

struct EggsView: View {
    @StateObject private var vm = EggsViewModel()
    
    var body: some View {
        NavigationView{
            ZStack {
                Color.backgroundMain.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 12) {
                    
                    Toggle(isOn: $vm.useSmartScale) {
                        Text("Use Smart Scale")
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        TextField("Weight (g)", text: $vm.weightInput)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.backgroundCard)
                            .cornerRadius(8)
                            .foregroundColor(.textPrimary)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                        
                        Text(weightClassificationBadgeText())
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .padding(10)
                            .background(vm.classificationBadgeColor)
                            .cornerRadius(10)
                            .foregroundColor(.backgroundMain)
                    }
                    .padding(.horizontal)
                    
                    TextField("Batch / Source (optional)", text: $vm.batchInput)
                        .padding(10)
                        .background(Color.backgroundCard)
                        .cornerRadius(8)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                    
                    TextField("Note (optional)", text: $vm.noteInput)
                        .padding(10)
                        .background(Color.backgroundCard)
                        .cornerRadius(8)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                    
                    DatePicker("Date", selection: $vm.dateInput, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .padding(.horizontal)
                        .accentColor(.yolkYellow)
                    
                    Button(action: {
                        vm.addEgg()
                        hideKeyboard()
                    }) {
                        Text("Weigh Egg")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.backgroundMain)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.yolkYellow)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(vm.weightInput.isEmpty)
                    
                    Divider()
                        .background(Color.textSecondary)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(vm.storage.eggs) { egg in
                            EggRowView(egg: egg)
                        }
                        .onDelete(perform: vm.deleteEgg)
                    }
                    .background(Color.backgroundMain)
                    .listStyle(.plain)
                }
                .navigationTitle("Eggs")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private func weightClassificationBadgeText() -> String {
        guard let weight = Int(vm.weightInput) else { return "-" }
        switch weight {
        case ..<53: return "S"
        case 53...62: return "M"
        case 63...72: return "L"
        default: return "XL"
        }
    }
}

struct EggRowView: View {
    let egg: Eggies
    
    var body: some View {
        HStack {
            Text("\(egg.weight) g")
                .font(.system(size: 20, design: .rounded))
                .foregroundColor(.textPrimary)
                .padding(.trailing, 8)
                .frame(width: 70, alignment: .leading)
            
            Text(egg.classification.rawValue)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(classificationColor())
                .frame(width: 40, alignment: .center)
                .padding(6)
                .background(classificationColor().opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading) {
                if let batch = egg.batch {
                    Text(batch)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.textSecondary)
                }
                if let note = egg.note {
                    Text(note)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .italic()
                }
            }
            Spacer()
            Text(dateFormatted(egg.date))
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.textSecondary)
        }
        .padding(8)
        .background(Color.backgroundCard)
        .cornerRadius(10)
    }
    
    private func classificationColor() -> Color {
        switch egg.classification {
        case .S: return .yolkYellow.opacity(0.7)
        case .M: return .yolkYellow
        case .L: return .yolkYellow.opacity(0.9)
        case .XL: return .yolkYellow
        }
    }
    
    private func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Keyboard Dismiss Helper
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif


extension Color {
    static let backgroundMain = Color(red: 31/255, green: 10/255, blue: 10/255)
    static let backgroundCard = Color(red: 42/255, green: 15/255, blue: 16/255)
    static let yolkYellow = Color(red: 255/255, green: 217/255, blue: 61/255)
    static let warningCoral = Color(red: 255/255, green: 107/255, blue: 107/255)
    static let textPrimary = Color(red: 249/255, green: 243/255, blue: 232/255)
    static let textSecondary = Color(red: 232/255, green: 198/255, blue: 106/255)
    static let chartYellow = Color(red: 255/255, green: 217/255, blue: 61/255)
    static let chartWhite = Color.white
    static let chartGray = Color(red: 199/255, green: 184/255, blue: 161/255)
}

enum Tab: Int {
    case dashboard, eggs, broilers, devices, statistics
}

struct ContentView: View {
    @State private var selectedTab: Tab = .dashboard
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }
                .tag(Tab.dashboard)
            
            EggsView()
                .tabItem {
                    Label("Eggs", systemImage: "moonphase.waxing.gibbous")
                }
                .tag(Tab.eggs)
            
            BroilersView()
                .tabItem {
                    Label("Broilers", systemImage: "circle.hexagonpath")
                }
                .tag(Tab.broilers)
            
            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.xaxis")
                }
                .tag(Tab.statistics)
        }
        .accentColor(.yolkYellow)
        .preferredColorScheme(.dark)
        .background(Color.backgroundMain.edgesIgnoringSafeArea(.all))
    }
}

struct Broiler: Identifiable, Codable {
    let id: UUID
    var batch: String
    var ageDays: Int
    var weightGrams: Int
    var note: String?
    var date: Date
    
    enum WeightStatus {
        case below, onTarget, above
    }
    
    var status: WeightStatus {
        if weightGrams < 1000 { return .below }
        else if weightGrams > 2000 { return .above }
        else { return .onTarget }
    }
    
    var weightKg: Double {
        Double(weightGrams) / 1000.0
    }
}

class BroilersStorage: ObservableObject {
    @Published var broilers: [Broiler] = []
    
    private let key = "EggWeightPro_Broilers"
    
    init() { load() }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            broilers = []
            return
        }
        if let decoded = try? JSONDecoder().decode([Broiler].self, from: data) {
            broilers = decoded.sorted(by: { $0.date > $1.date })
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(broilers) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func addBroiler(weightGrams: Int, ageDays: Int, batch: String, note: String? = nil, date: Date = Date()) {
        let newBroiler = Broiler(id: UUID(), batch: batch, ageDays: ageDays, weightGrams: weightGrams, note: note, date: date)
        broilers.insert(newBroiler, at: 0)
        save()
    }
    
    func delete(at offsets: IndexSet) {
        broilers.remove(atOffsets: offsets)
        save()
    }
}

class DashboardViewModel: ObservableObject {
    @Published var eggsCountToday: Int = 0
    @Published var broilersCountToday: Int = 0
    @Published var avgEggWeight7Days: Double = 0
    @Published var avgBroilerWeightByBatch: String = "-"
    
    private var eggsStorage: EggStorage
    private var broilersStorage: BroilersStorage
    
    private var cancellables = Set<AnyCancellable>()
    
    init(eggsStorage: EggStorage, broilersStorage: BroilersStorage) {
        self.eggsStorage = eggsStorage
        self.broilersStorage = broilersStorage
        setupBindings()
    }
    
    private func setupBindings() {
        Publishers.CombineLatest(eggsStorage.$eggs, broilersStorage.$broilers)
            .sink { [weak self] eggs, broilers in
                self?.calculate(eggs: eggs, broilers: broilers)
            }
            .store(in: &cancellables)
    }
    
    private func calculate(eggs: [Eggies], broilers: [Broiler]) {
        let today = Calendar.current.startOfDay(for: Date())
        
        eggsCountToday = eggs.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) }.count
        
        broilersCountToday = broilers.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) }.count
        
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today
        let eggsLast7Days = eggs.filter { $0.date >= sevenDaysAgo }
        avgEggWeight7Days = eggsLast7Days.isEmpty ? 0 : eggsLast7Days.map { Double($0.weight) }.reduce(0, +) / Double(eggsLast7Days.count)
        
        let grouped = Dictionary(grouping: broilers, by: { $0.batch })
        if let firstBatch = grouped.first {
            let batchName = firstBatch.key
            let avgWeightKg = firstBatch.value.map { $0.weightKg }.reduce(0, +) / Double(firstBatch.value.count)
            avgBroilerWeightByBatch = "\(batchName): \(String(format: "%.2f", avgWeightKg)) kg"
        } else {
            avgBroilerWeightByBatch = "-"
        }
    }
}

class BroilersViewModel: ObservableObject {
    @Published var weightInput: String = ""
    @Published var ageInput: String = ""
    @Published var batchInput: String = ""
    @Published var noteInput: String = ""
    @Published var dateInput: Date = Date()
    
    @ObservedObject var storage = BroilersStorage()
    
    func addBroiler() {
        guard let weight = Int(weightInput), weight > 0,
              let age = Int(ageInput), age >= 0,
              !batchInput.isEmpty else { return }
        
        storage.addBroiler(weightGrams: weight, ageDays: age, batch: batchInput, note: noteInput.isEmpty ? nil : noteInput, date: dateInput)
        clearInputs()
    }
    
    func clearInputs() {
        weightInput = ""
        ageInput = ""
        batchInput = ""
        noteInput = ""
        dateInput = Date()
    }
    
    func delete(at offsets: IndexSet) {
        storage.delete(at: offsets)
    }
}

struct DashboardView: View {
    @StateObject private var eggsStorage = EggStorage()
    @StateObject private var broilersStorage = BroilersStorage()
    
    @StateObject private var vm: DashboardViewModel
    
    @State private var showAddMenu = false
    
    init() {
        let eggsStorage = EggStorage()
        let broilersStorage = BroilersStorage()
        _eggsStorage = StateObject(wrappedValue: eggsStorage)
        _broilersStorage = StateObject(wrappedValue: broilersStorage)
        _vm = StateObject(wrappedValue: DashboardViewModel(eggsStorage: eggsStorage, broilersStorage: broilersStorage))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundMain.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    
                    HStack(spacing: 12) {
                        dashboardCard(title: "Today", content:
                            VStack {
                                Text("\(vm.eggsCountToday) Eggs")
                                Text("\(vm.broilersCountToday) Broilers")
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        )
                        
                        dashboardCard(title: "Avg Egg Weight (7d)", content:
                            Text(vm.avgEggWeight7Days > 0 ? String(format: "%.1f g", vm.avgEggWeight7Days) : "-")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.textPrimary)
                        )
                    }
                    .frame(maxWidth: .infinity)
                    
                    dashboardCard(title: "Avg Broiler Weight by Batch", content:
                        Text(vm.avgBroilerWeightByBatch)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary)
                    )
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            showAddMenu.toggle()
                        }
                    } label: {
                        Text("+ Add")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color.backgroundMain)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yolkYellow)
                            .cornerRadius(15)
                            .padding(.horizontal)
                    }
                    
                }
                .padding()
                
                if showAddMenu {
                    addMenuOverlay
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func dashboardCard<Content: View>(title: String, content: Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.textSecondary)
                .textCase(.uppercase)
            
            content
        }
        .padding()
        .background(Color.backgroundCard)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.4), radius: 4, x: 1, y: 2)
    }
    
    var addMenuOverlay: some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 12) {
                Text("Add Weight")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Button {
                    print("Add Egg tapped")
                    showAddMenu = false
                } label: {
                    Text("Egg Weight")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.backgroundMain)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yolkYellow)
                        .cornerRadius(12)
                }
                
                Button {
                    print("Add Broiler tapped")
                    showAddMenu = false
                } label: {
                    Text("Broiler Weight")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.backgroundMain)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yolkYellow)
                        .cornerRadius(12)
                }
                
                Button {
                    withAnimation {
                        showAddMenu = false
                    }
                } label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.warningCoral)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color.backgroundCard)
            .cornerRadius(20)
            .padding()
            .shadow(radius: 10)
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea())
        .onTapGesture {
            withAnimation {
                showAddMenu = false
            }
        }
    }
}

struct BroilersView: View {
    @StateObject private var vm = BroilersViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundMain.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 12) {
                    ScrollView {
                        VStack(spacing: 12) {
                            Group {
                                TextField("Weight (g)", text: $vm.weightInput)
                                    .keyboardType(.numberPad)
                                TextField("Age (days)", text: $vm.ageInput)
                                    .keyboardType(.numberPad)
                                TextField("Batch *", text: $vm.batchInput)
                                    .textInputAutocapitalization(.words)
                                TextField("Note (optional)", text: $vm.noteInput)
                                DatePicker("Date", selection: $vm.dateInput, displayedComponents: .date)
                                    .accentColor(.yolkYellow)
                                    .labelsHidden()
                            }
                            .padding()
                            .background(Color.backgroundCard)
                            .cornerRadius(10)
                            .foregroundColor(.textPrimary)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            
                            Button {
                                vm.addBroiler()
                                hideKeyboard()
                            } label: {
                                Text("Weigh Broiler")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.yolkYellow)
                                    .cornerRadius(12)
                                    .foregroundColor(Color.backgroundMain)
                            }
                            .disabled(vm.weightInput.isEmpty || vm.ageInput.isEmpty || vm.batchInput.isEmpty)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .background(Color.textSecondary)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(vm.storage.broilers) { broiler in
                            BroilerRow(broiler: broiler)
                        }
                        .onDelete(perform: vm.delete)
                    }
                    .listStyle(.plain)
                    .background(Color.clear)
                }
                .navigationTitle("Broilers")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}


struct BroilerRow: View {
    let broiler: Broiler
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(broiler.weightGrams) g, \(broiler.ageDays) d")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                HStack {
                    Text("Batch: \(broiler.batch)")
                    if let note = broiler.note {
                        Text("Note: \(note)").italic()
                    }
                }
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.textSecondary)
            }
            Spacer()
            
            weightStatusBadge(status: broiler.status)
        }
        .padding(8)
        .background(Color.backgroundCard)
        .cornerRadius(10)
    }
    
    @ViewBuilder
    func weightStatusBadge(status: Broiler.WeightStatus) -> some View {
        switch status {
        case .below:
            Text("Below")
                .foregroundColor(.warningCoral)
                .padding(6)
                .background(Color.warningCoral.opacity(0.2))
                .cornerRadius(8)
        case .onTarget:
            Text("On target")
                .foregroundColor(.yolkYellow)
                .padding(6)
                .background(Color.yolkYellow.opacity(0.2))
                .cornerRadius(8)
        case .above:
            Text("Above")
                .foregroundColor(.yolkYellow)
                .padding(6)
                .background(Color.yolkYellow.opacity(0.6))
                .cornerRadius(8)
        }
    }
}

struct DevicesView: View {
    var body: some View {
        ZStack {
            Color.backgroundMain.edgesIgnoringSafeArea(.all)
            VStack {
                Text("Devices")
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding()
        }
    }
}

import Charts

struct StatisticsView: View {
    @StateObject private var eggsStorage = EggStorage()
    @StateObject private var broilersStorage = BroilersStorage()
    
    @State private var selectedTab: StatTab = .eggs
    
    enum StatTab: String, CaseIterable {
        case eggs = "Eggs"
        case broilers = "Broilers"
        case summary = "Summary"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundMain.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    Picker("Statistics", selection: $selectedTab) {
                        ForEach(StatTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .background(Color.backgroundCard)
                    .cornerRadius(10)
                    
                    ScrollView {
                        switch selectedTab {
                        case .eggs:
                            EggStatisticsView(storage: eggsStorage)
                        case .broilers:
                            BroilerStatisticsView(storage: broilersStorage)
                        case .summary:
                            SummaryStatisticsView(eggs: eggsStorage.eggs, broilers: broilersStorage.broilers)
                        }
                    }
                }
                .navigationTitle("Statistics")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

extension Eggies.Classification: Hashable, CaseIterable {
    public static var allCases: [Eggies.Classification] = [.S, .M, .L, .XL]
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

// MARK: - Исправленный EggStatisticsView
struct EggStatisticsView: View {
    let storage: EggStorage
    
    var body: some View {
        VStack(spacing: 16) {
            if let chartData = classificationChartData {
                Chart {
                    ForEach(chartData) { item in
                        BarMark(
                            x: .value("Class", item.classification.rawValue),
                            y: .value("Count", item.count)
                        )
                        .foregroundStyle(classificationColor(for: item.classification))
                    }
                }
                .frame(height: 200)
                .background(Color.backgroundCard)
                .cornerRadius(15)
                .chartLegend(.visible)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            } else {
                emptyChartPlaceholder
            }
            
            EggWeightTrendChart(eggs: storage.eggs)
                .frame(height: 250)
        }
        .padding()
    }
    
    private var classificationChartData: [ClassificationItem]? {
        let counts = Dictionary(grouping: storage.eggs, by: { $0.classification })
        return Eggies.Classification.allCases.compactMap { classification in
            let count = counts[classification]?.count ?? 0
            return ClassificationItem(classification: classification, count: count)
        }
    }
    
    private func classificationColor(for classification: Eggies.Classification) -> Color {
        switch classification {
        case .S: return Color.yolkYellow.opacity(0.6)
        case .M: return Color.yolkYellow.opacity(0.8)
        case .L: return Color.yolkYellow
        case .XL: return Color.chartWhite.opacity(0.8)
        }
    }
    
    private var emptyChartPlaceholder: some View {
        VStack {
            Text("No egg data yet")
                .foregroundColor(.textSecondary)
                .font(.system(size: 16, design: .rounded))
            Image(systemName: "chart.bar")
                .font(.system(size: 48))
                .foregroundColor(.textSecondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
        .background(Color.backgroundCard)
        .cornerRadius(15)
    }
}

struct EggWeightTrendChart: View {
    let eggs: [Eggies]
    
    var body: some View {
        if let chartData = trendChartData {
            Chart {
                ForEach(chartData) { item in
                    LineMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Weight", item.avgWeight)
                    )
                    .foregroundStyle(Color.yolkYellow)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Weight", item.avgWeight)
                    )
                    .foregroundStyle(Color.yolkYellow)
                    .symbolSize(80)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .background(Color.backgroundCard)
            .cornerRadius(15)
        } else {
            emptyChartPlaceholder
        }
    }
    
    private var trendChartData: [TrendItem]? {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let grouped = Dictionary(grouping: eggs, by: { calendar.startOfDay(for: $0.date) })
        return grouped.map { date, items in
            TrendItem(date: date, avgWeight: Double(items.map { $0.weight }.reduce(0, +)) / Double(items.count))
        }
        .sorted { $0.date > $1.date }
        .prefix(30)
        .sorted { $0.date < $1.date }
    }
    
    private var emptyChartPlaceholder: some View {
        Text("No egg data yet")
            .foregroundColor(.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: 250)
            .background(Color.backgroundCard)
            .cornerRadius(15)
    }
}

// MARK: - Статистика бройлеров
struct BroilerStatisticsView: View {
    let storage: BroilersStorage
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Broiler growth trends")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            if !storage.broilers.isEmpty {
                ForEach(batchAverages) { batchAvg in
                    HStack {
                        Text(batchAvg.batch)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("\(String(format: "%.1f g", batchAvg.avgWeight))")
                            .foregroundColor(.yolkYellow)
                            .font(.system(size: 14 ,weight: .semibold))
                    }
                    .padding()
                    .background(Color.backgroundCard.opacity(0.8))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
    }
    
    private var batchAverages: [BatchAverage] {
        let grouped = Dictionary(grouping: storage.broilers, by: { $0.batch })
        return grouped.map { batch, broilers in
            let totalWeight = broilers.map { Double($0.weightGrams) }.reduce(0, +)
            return BatchAverage(batch: batch, avgWeight: totalWeight / Double(broilers.count))
        }
    }
}

struct SummaryStatisticsView: View {
    let eggs: [Eggies]
    let broilers: [Broiler]
    
    var body: some View {
        VStack(spacing: 12) {
            statCard(title: "Total Eggs", value: "\(eggs.count)")
            statCard(title: "Total Broilers", value: "\(broilers.count)")
            statCard(title: "Avg Egg Weight", value: avgEggWeightString)
            statCard(title: "Avg Broiler Weight", value: avgBroilerWeightString)
        }
        .padding()
    }
    
    private var avgEggWeightString: String {
        let avg = eggs.isEmpty ? 0 : eggs.map { Double($0.weight) }.reduce(0, +) / Double(eggs.count)
        return String(format: "%.1f g", avg)
    }
    
    private var avgBroilerWeightString: String {
        let avg = broilers.isEmpty ? 0 : broilers.map { Double($0.weightGrams) }.reduce(0, +) / Double(broilers.count)
        return String(format: "%.1f g", avg)
    }
    
    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.yolkYellow)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.backgroundCard)
        .cornerRadius(15)
    }
}

struct ClassificationItem: Identifiable {
    let id = UUID()
    let classification: Eggies.Classification
    let count: Int
}

struct TrendItem: Identifiable {
    let id = UUID()
    let date: Date
    let avgWeight: Double
}

struct BatchAverage: Identifiable {
    let id = UUID()
    let batch: String
    let avgWeight: Double
}

#Preview {
    ContentView()
}
