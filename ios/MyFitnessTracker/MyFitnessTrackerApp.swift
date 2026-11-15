import SwiftUI
import UIKit
import UserNotifications

@main
struct MyFitnessTrackerApp: App {
    @StateObject private var store = FitnessStore()
    var body: some Scene {
        WindowGroup { RootView().environmentObject(store).preferredColorScheme(store.profile.darkMode ? .dark : .light) }
    }
}

struct Meal: Identifiable, Codable { var id: String; var name: String; var foods: [String] }
struct Exercise: Identifiable, Codable { var id: String; var name: String; var sets: Int; var reps: String; var weight: String = ""; var done: Set<Int> = []; var actual: [String] = []; var note: String = "" }
struct Measurement: Identifiable, Codable { var id = UUID(); var date: Date; var weight: Double?; var waist: Double? }
struct Profile: Codable { var name = ""; var age = 27; var height = 167.0; var weight = 74.0; var targetWeight = 68.0; var waist = 100.0; var calories = 1850; var protein = 135; var water = 2500; var stepsTarget = 8000; var darkMode = true; var beginner = true }
struct DayRecord: Codable { var tasks: Set<Int> = []; var meals: Set<String> = []; var water = 0; var steps = 0; var sleep = ""; var calories = ""; var protein = "" }

@MainActor final class FitnessStore: ObservableObject {
    @Published var profile = Profile() { didSet { save() } }
    @Published var records: [String: DayRecord] = [:] { didSet { save() } }
    @Published var workouts: [String: [Exercise]] = [:] { didSet { save() } }
    @Published var measurements: [Measurement] = [] { didSet { save() } }
    private let storageKey = "my-fitness-tracker-native-v1"
    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    let tasks = ["Morning routine", "Breakfast", "Lunch", "Evening snack", "Gym preparation", "Workout", "Post-workout recovery", "Dinner", "Hydration and activity", "Night routine"]
    let meals: [String: [Meal]] = [
        "Monday": [Meal(id:"night",name:"One meal at night · fasting day",foods:["Banana · 100–120 g edible","Apple · 150 g edible","Almonds · 15 g","Makhana · 30 g dry","Milk · 300 ml","Curd · 250 g","Paneer · 200 g (if allowed)","Whey · 1 labelled serving (if allowed)"])],
        "Tuesday": [Meal(id:"breakfast",name:"Oats bowl",foods:["Oats · 50 g dry","Milk · 250 ml","Whey · 1 labelled serving","Chia · 5 g"]),Meal(id:"lunch",name:"Soya and rotis",foods:["Soya chunks · 50 g dry","Atta · 60 g dry (2 small rotis)","Curd · 200 g","Vegetables · 150 g"]),Meal(id:"snack",name:"Chana, apple and almonds",foods:["Roasted chana · 30 g","Apple · 150 g edible","Almonds · 10 g"]),Meal(id:"dinner",name:"Paneer, dal and rice",foods:["Paneer · 150 g","Dal · 50 g dry","Rice · 40 g dry","Vegetables · 150 g"])],
        "Wednesday": [Meal(id:"breakfast",name:"Besan chilla and paneer",foods:["Besan · 60 g dry","Paneer · 50 g","Curd · 150 g","Vegetables · 50 g","Whey · 1 labelled serving"]),Meal(id:"lunch",name:"Rajma rice",foods:["Rajma · 50 g dry","Rice · 40 g dry","Curd · 150 g","Salad · 150 g"]),Meal(id:"snack",name:"High-protein curd and fruit",foods:["High-protein curd · 200 g","Fruit · 150 g","Chia · 10 g"]),Meal(id:"dinner",name:"Tofu, rotis and dal",foods:["Tofu · 200 g","Atta · 60 g dry (2 rotis)","Dal · 40 g dry","Vegetables · 100 g"])],
        "Thursday": [Meal(id:"breakfast",name:"Moong and paneer",foods:["Moong dal · 60 g dry","Paneer · 75 g","Curd · 100 g","Whey · 1 labelled serving"]),Meal(id:"lunch",name:"Chole and rotis",foods:["Chole · 50 g dry","Atta · 60 g dry","Curd · 200 g","Salad · 150 g"]),Meal(id:"snack",name:"Makhana and milk",foods:["Makhana · 30 g dry","Milk · 250 ml"]),Meal(id:"dinner",name:"Soya rice bowl",foods:["Soya chunks · 50 g dry","Rice · 40 g dry","Curd · 150 g","Vegetables · 150 g"])],
        "Friday": [Meal(id:"breakfast",name:"Paneer toast",foods:["Whole-wheat bread · 60 g","Paneer · 100 g","Vegetables · 50 g","Whey · 1 labelled serving"]),Meal(id:"lunch",name:"Paneer rotis",foods:["Paneer · 150 g","Atta · 60 g","Curd · 150 g","Salad · 150 g"]),Meal(id:"snack",name:"Roasted chana and fruit",foods:["Roasted chana · 30 g","Fruit · 150 g"]),Meal(id:"dinner",name:"Moong, rice and tofu",foods:["Moong dal · 40 g dry","Rice · 35 g dry","Tofu · 200 g","Curd · 100 g","Vegetables · 100 g"])],
        "Saturday": [Meal(id:"breakfast",name:"Oats bowl",foods:["Oats · 50 g dry","Milk · 250 ml","Whey · 1 labelled serving","Chia · 5 g"]),Meal(id:"lunch",name:"Soya rice bowl",foods:["Soya chunks · 50 g dry","Rice · 40 g dry","Vegetables · 150 g","Curd · 200 g"]),Meal(id:"snack",name:"High-protein curd and almonds",foods:["High-protein curd · 200 g","Almonds · 10 g"]),Meal(id:"dinner",name:"Palak paneer and roti",foods:["Paneer · 150 g","Spinach · 150 g","Atta · 60 g","Dal · 30 g dry"])],
        "Sunday": [Meal(id:"breakfast",name:"Idli and sambar",foods:["Idli · approximately 150 g cooked","Sambar · 200 g cooked","Whey · 1 labelled serving"]),Meal(id:"lunch",name:"Tofu rice bowl",foods:["Tofu · 200 g","Rice · 40 g dry","Curd · 150 g","Vegetables · 150 g"]),Meal(id:"snack",name:"Fruit, chia and milk",foods:["Fruit · 150 g edible","Chia · 10 g","Milk · 250 ml"]),Meal(id:"dinner",name:"Rajma, roti and paneer",foods:["Rajma · 50 g dry","Atta · 60 g dry","Paneer · 100 g","Salad · 150 g"])]]
    let routines: [String: [(String, Int, String)]] = [
        "Tuesday":[("Incline dumbbell press",3,"8–12"),("Machine chest press",2,"10–12"),("Seated shoulder press",2,"8–12"),("Lateral raises",3,"12–20"),("Triceps pushdown",3,"10–15"),("Overhead triceps extension",2,"12–15")],
        "Wednesday":[("Lat pulldown",3,"8–12"),("Chest-supported row",3,"8–12"),("Single-arm cable pulldown",2,"10–15"),("Reverse pec deck",3,"12–20"),("EZ-bar curl",3,"10–12"),("Hammer curl",2,"12–15")],
        "Thursday":[("Leg press",3,"10–12"),("Goblet squat",2,"10–12"),("Romanian deadlift",3,"8–12"),("Seated leg curl",3,"10–15"),("Calf raises",3,"12–20"),("Cable crunch",3,"12–15"),("Plank",2,"30–45 sec")],
        "Friday":[("Assisted pull-ups",3,"8–10"),("Incline machine press",3,"10–12"),("Seated cable row",2,"10–12"),("Cable lateral raise",4,"12–20"),("Rear delt cable fly",3,"12–15"),("Straight-arm pulldown",2,"12–15")],
        "Saturday":[("Hack squat or leg press",3,"8–12"),("Romanian deadlift",2,"10–12"),("Leg extension",2,"12–15"),("Seated leg curl",2,"12–15"),("Dumbbell curl",3,"10–12"),("Rope triceps pushdown",3,"10–12"),("Hanging knee raise",3,"10–15")]
    ]
    init() {
        guard let data = UserDefaults.standard.data(forKey: storageKey), let saved = try? JSONDecoder().decode(SavedState.self, from: data) else { return }
        profile = saved.profile; records = saved.records; workouts = saved.workouts; measurements = saved.measurements
    }
    var today: String { Self.key(Date()) }
    var todayDay: String { Calendar.current.weekdaySymbols[(Calendar.current.component(.weekday, from: Date()) + 5) % 7] }
    func record(_ date: String? = nil) -> DayRecord { records[date ?? today] ?? DayRecord() }
    func setRecord(_ value: DayRecord, date: String? = nil) { records[date ?? today] = value }
    func save() { let value = SavedState(profile:profile,records:records,workouts:workouts,measurements:measurements); if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data,forKey:storageKey) } }
    static func key(_ date: Date) -> String { let f=DateFormatter(); f.dateFormat="yyyy-MM-dd"; return f.string(from:date) }
    func setDone(_ index: Int, done: Bool) { var r=record(); if done { r.tasks.insert(index) } else { r.tasks.remove(index) }; setRecord(r) }
    func setMeal(_ id: String, done: Bool) { var r=record(); if done { r.meals.insert(id) } else { r.meals.remove(id) }; setRecord(r) }
    func updateExercise(_ exercise: Exercise, at index: Int) { var list=workouts[today] ?? []; if index < list.count { list[index]=exercise }; workouts[today]=list }
    func loadWorkout() -> [Exercise] { (routines[todayDay] ?? []).enumerated().map { index, item in let id="\(todayDay)-\(index)"; return workouts[today]?.first(where:{$0.id==id}) ?? Exercise(id:id,name:item.0,sets:profile.beginner ? min(2,item.1):item.1,reps:item.2) } }
}
private struct SavedState: Codable { var profile: Profile; var records: [String:DayRecord]; var workouts: [String:[Exercise]]; var measurements: [Measurement] }

struct RootView: View {
    @EnvironmentObject private var store: FitnessStore
    var body: some View {
        TabView {
            TodayView().tabItem { Label("Today",systemImage:"sun.max") }
            PlanView().tabItem { Label("Plan",systemImage:"calendar") }
            WorkoutView().tabItem { Label("Train",systemImage:"dumbbell") }
            ProgressViewNative().tabItem { Label("Progress",systemImage:"chart.xyaxis.line") }
            SettingsView().tabItem { Label("Settings",systemImage:"gearshape") }
        }.tint(Color(red:0.68,green:0.91,blue:0.39))
    }
}

struct Screen: ViewModifier { func body(content: Content) -> some View { content.background(Color(uiColor:.systemGroupedBackground)).toolbarBackground(.visible,for:.tabBar) } }
extension View { func appScreen() -> some View { modifier(Screen()) } }

struct TodayView: View {
    @EnvironmentObject private var store: FitnessStore
    private var record: DayRecord { store.record() }
    var body: some View { NavigationStack { List {
        Section { VStack(alignment:.leading,spacing:10) { Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())).font(.subheadline).foregroundStyle(.secondary); Text(store.routines[store.todayDay] == nil ? (store.todayDay == "Monday" ? "Fasting + recovery" : "Recovery") : store.todayDay == "Tuesday" ? "Push day" : store.todayDay == "Wednesday" ? "Pull day" : store.todayDay == "Thursday" ? "Legs + core" : store.todayDay == "Friday" ? "Upper body" : "Lower body + arms").font(.title2.bold()); ProgressView(value:Double(record.tasks.count),total:Double(store.tasks.count)); Text("\(record.tasks.count) of \(store.tasks.count) tasks complete").font(.caption).foregroundStyle(.secondary) }.padding(.vertical,6) }
        Section("Daily targets") { HStack { metric("Calories",record.calories.isEmpty ? "—" : record.calories,"/ \(store.profile.calories) kcal"); Spacer(); metric("Protein",record.protein.isEmpty ? "—" : record.protein,"/ \(store.profile.protein) g") }; HStack { metric("Water","\(record.water)","/ \(store.profile.water) ml"); Button("+ 250 ml") { var r=record;r.water += 250;store.setRecord(r) } }; HStack { metric("Steps",record.steps == 0 ? "—" : "\(record.steps)","/ \(store.profile.stepsTarget)"); Button("Update") { stepEntry() } } }
        Section("Checklist") { ForEach(Array(store.tasks.enumerated()),id:\.offset) { i, task in Toggle(task,isOn:Binding(get:{record.tasks.contains(i)},set:{store.setDone(i,done:$0)})) } }
        Section("Meals · \(store.todayDay)") { ForEach(store.meals[store.todayDay] ?? []) { meal in NavigationLink { MealDetail(meal:meal) } label: { Toggle(isOn:Binding(get:{record.meals.contains(meal.id)},set:{store.setMeal(meal.id,done:$0)})) { VStack(alignment:.leading){Text(meal.name);Text(meal.foods.count.description+" ingredients").font(.caption).foregroundStyle(.secondary)} } } } }
        Section("Quick check-in") { HStack { Text("Sleep (hours)"); Spacer(); TextField("—",text:Binding(get:{record.sleep},set:{var r=record;r.sleep=$0;store.setRecord(r)})).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width:70) }; HStack { Text("Calories eaten"); Spacer(); TextField("kcal",text:Binding(get:{record.calories},set:{var r=record;r.calories=$0;store.setRecord(r)})).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width:90) }; HStack { Text("Protein eaten"); Spacer(); TextField("grams",text:Binding(get:{record.protein},set:{var r=record;r.protein=$0;store.setRecord(r)})).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width:90) } }
    }.navigationTitle("My Fitness").appScreen() } }
    private func metric(_ title:String,_ value:String,_ target:String)->some View { VStack(alignment:.leading){Text(title).font(.caption).foregroundStyle(.secondary);Text(value).font(.title3.bold());Text(target).font(.caption2).foregroundStyle(.secondary)} }
    private func stepEntry(){let alert=UIAlertController(title:"Update steps",message:nil,preferredStyle:.alert);alert.addTextField{$0.keyboardType = .numberPad;$0.placeholder="Steps"};alert.addAction(UIAlertAction(title:"Cancel",style:.cancel));alert.addAction(UIAlertAction(title:"Save",style:.default){_ in var r=record;r.steps=Int(alert.textFields?.first?.text ?? "") ?? r.steps;store.setRecord(r)});UIApplication.shared.firstKeyWindow?.rootViewController?.present(alert,animated:true)}
}

struct MealDetail: View { let meal:Meal; var body:some View { List { Section("Ingredients and quantities") { ForEach(meal.foods,id:\.self){Text($0)} }; Section("Nutrition") { Text("Nutrition totals are not estimated. Use verified package labels and food data for your ingredients.").foregroundStyle(.secondary) } }.navigationTitle(meal.name).navigationBarTitleDisplayMode(.inline) } }

struct PlanView: View {
    @EnvironmentObject private var store: FitnessStore
    var body: some View {
        NavigationStack {
            List {
                Section { Text("Strict vegetarian · no eggs, meat or fish. Dairy allowed. Monday: one meal at night; no heavy workout.").font(.subheadline).foregroundStyle(.secondary) }
                ForEach(store.days, id: \.self) { day in
                    Section { ForEach(store.meals[day] ?? []) { meal in
                        NavigationLink { MealDetail(meal: meal) } label: {
                            VStack(alignment: .leading, spacing: 4) { Text(meal.name).font(.headline); Text(meal.foods.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary).lineLimit(3) }
                        }
                    } } header: { Text("\(day) · \(day == "Monday" ? "Fasting" : day == "Sunday" ? "Recovery" : "Training")") }
                }
            }.navigationTitle("Weekly plan").appScreen()
        }
    }
}

struct WorkoutView: View { @EnvironmentObject private var store:FitnessStore; @State private var seconds=90; @State private var ticking=false; var body:some View { NavigationStack { List { Section { VStack(alignment:.leading,spacing:8){Text(store.todayDay.uppercased()).font(.caption.bold()).foregroundStyle(.green);Text(store.routines[store.todayDay] == nil ? "Recovery day" : "\(store.routines[store.todayDay]?.count ?? 0) exercises").font(.title2.bold());Text(store.profile.beginner ? "Beginner return · about 2 sets · keep 3–4 reps in reserve" : "Standard working sets").font(.caption).foregroundStyle(.secondary);Text("Warm-up: 5–8 minutes easy cardio and gradual warm-up sets.").font(.caption)}.padding(.vertical,5) }; if store.routines[store.todayDay] != nil { Section("Working sets") { ForEach(Array(store.loadWorkout().enumerated()),id:\.element.id){ index, exercise in ExerciseRow(exercise:exercise,index:index) } } } else { Section { Text(store.todayDay == "Sunday" ? "Recovery walk 20–30 minutes and mobility 10 minutes." : "Fasting and recovery. Skip heavy gym training.") } }; Section("Rest timer") { HStack { Text(String(format:"%02d:%02d",seconds/60,seconds%60)).font(.title.monospacedDigit()); Spacer(); Button(ticking ? "Pause" : "Start") { ticking.toggle(); if ticking { Timer.scheduledTimer(withTimeInterval:1,repeats:true){ timer in if !ticking || seconds<=0 { timer.invalidate();ticking=false } else { seconds-=1 } } } }; Button("Reset") {seconds=90;ticking=false} } }; Section("Recent sessions") { ForEach(store.workouts.keys.sorted().reversed().prefix(7),id:\.self){day in Text("\(day) · \(store.workouts[day]?.filter{!$0.done.isEmpty}.count ?? 0) exercises logged")} } }.navigationTitle("Workout").appScreen() } } }
struct ExerciseRow: View { @EnvironmentObject private var store:FitnessStore; @State var exercise:Exercise; let index:Int; var body:some View { DisclosureGroup { HStack { Text("Weight (kg)");TextField("0",text:$exercise.weight).keyboardType(.decimalPad).multilineTextAlignment(.trailing).onChange(of:exercise.weight){save()} }; ForEach(0..<exercise.sets,id:\.self){n in HStack { Toggle("Set \(n+1)",isOn:Binding(get:{exercise.done.contains(n)},set:{if $0{exercise.done.insert(n)}else{exercise.done.remove(n)};save()}));Text("Target \(exercise.reps)").font(.caption).foregroundStyle(.secondary);TextField("Actual",text:Binding(get:{n<exercise.actual.count ? exercise.actual[n]:""},set:{if n>=exercise.actual.count{exercise.actual += Array(repeating:"",count:n-exercise.actual.count+1)};exercise.actual[n]=$0;save()})).keyboardType(.numberPad).frame(width:55) } }; TextField("Exercise notes",text:$exercise.note,axis:.vertical).onChange(of:exercise.note){save()} } label:{VStack(alignment:.leading){Text(exercise.name).font(.headline);Text("\(exercise.sets) sets · \(exercise.reps) reps").font(.caption).foregroundStyle(.secondary)}}.onAppear{if let current=store.workouts[store.today]?.first(where:{$0.id==exercise.id}){exercise=current}} }; private func save(){store.updateExercise(exercise,at:index)} }

struct ProgressViewNative: View { @EnvironmentObject private var store:FitnessStore; @State private var showEntry=false; @State private var weight=""; @State private var waist=""; var body:some View { NavigationStack { List { Section { Button("+ Record weight / waist") {showEntry=true}; Text("Only recorded measurements are shown.").font(.caption).foregroundStyle(.secondary) }; Section("Measurements") { if store.measurements.isEmpty { ContentUnavailableView("No measurements yet",systemImage:"chart.xyaxis.line",description:Text("Add a weight or waist measurement to start your history.")) } else { ForEach(store.measurements.sorted{$0.date>$1.date}){m in HStack{Text(m.date.formatted(date:.abbreviated,time:.omitted));Spacer();if let w=m.weight{Text("\(w.formatted()) kg")};if let c=m.waist{Text("\(c.formatted()) cm").foregroundStyle(.secondary)}}} } }; Section("Weekly consistency") { let last7=(0..<7).map{ i -> Double in var date=Calendar.current.date(byAdding:.day,value:-i,to:Date())!;date=Calendar.current.startOfDay(for:date);let count=store.record(FitnessStore.key(date)).tasks.count;return Double(count)/Double(store.tasks.count) }; Text("Average checklist completion: \(Int(last7.reduce(0,+)/7*100))%") } }.navigationTitle("Progress").sheet(isPresented:$showEntry){NavigationStack{Form{TextField("Weight (kg)",text:$weight).keyboardType(.decimalPad);TextField("Waist (cm)",text:$waist).keyboardType(.decimalPad)}.navigationTitle("Measurement").toolbar{ToolbarItem(placement:.cancellationAction){Button("Cancel"){showEntry=false}};ToolbarItem(placement:.confirmationAction){Button("Save"){let m=Measurement(date:Date(),weight:Double(weight),waist:Double(waist));store.measurements.append(m);showEntry=false;weight="";waist=""}}}}}.appScreen() } } }

struct SettingsView: View { @EnvironmentObject private var store:FitnessStore; var body:some View { NavigationStack { Form { Section("Profile") { TextField("Name",text:$store.profile.name);Stepper("Age · \(store.profile.age)",value:$store.profile.age,in:13...100);numberField("Height (cm)",$store.profile.height);numberField("Current weight (kg)",$store.profile.weight);numberField("Target weight (kg)",$store.profile.targetWeight);numberField("Waist (cm)",$store.profile.waist) }; Section("Daily targets") { Stepper("Calories · \(store.profile.calories) kcal",value:$store.profile.calories,in:500...5000,step:50);Stepper("Protein · \(store.profile.protein) g",value:$store.profile.protein,in:20...300,step:5);Stepper("Water · \(store.profile.water) ml",value:$store.profile.water,in:500...7000,step:250);Stepper("Steps · \(store.profile.stepsTarget)",value:$store.profile.stepsTarget,in:1000...30000,step:500) }; Section("Preferences") { Toggle("Beginner return volume",isOn:$store.profile.beginner);Toggle("Dark appearance",isOn:$store.profile.darkMode) }; Section("Reminders") { Button("Request notification permission"){UNUserNotificationCenter.current().requestAuthorization(options:[.alert,.sound,.badge]){_,_ in}}; Text("iOS controls notification delivery. Background reminders need scheduling and are not enabled in this build.").font(.caption).foregroundStyle(.secondary) }; Section("Data") { Button("Export backup"){export()}; Text("Records are stored locally on this iPhone. No cloud account or sync is configured.").font(.caption).foregroundStyle(.secondary) }; Section { Text("Nutrition values are not guessed. Enter actual calories and protein on Today using verified labels and food data.").font(.caption).foregroundStyle(.secondary) } }.navigationTitle("Settings").appScreen() } }; private func numberField(_ title:String,_ value:Binding<Double>)->some View { HStack{Text(title);Spacer();TextField("",value:value,format:.number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width:90)} }; private func export(){let state=SavedState(profile:store.profile,records:store.records,workouts:store.workouts,measurements:store.measurements);guard let data=try? JSONEncoder().encode(state) else{return};let url=FileManager.default.temporaryDirectory.appendingPathComponent("fitness-backup.json");try? data.write(to:url);let av=UIActivityViewController(activityItems:[url],applicationActivities:nil);UIApplication.shared.firstKeyWindow?.rootViewController?.present(av,animated:true)} }

extension UIApplication { var firstKeyWindow:UIWindow? { connectedScenes.compactMap{$0 as? UIWindowScene}.flatMap{$0.windows}.first{$0.isKeyWindow} } }
