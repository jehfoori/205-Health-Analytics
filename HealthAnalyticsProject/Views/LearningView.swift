import SwiftUI

struct LearningView: View {
    var body: some View {
        NavigationView {
            List {
                // SECTION 1: Therapeutic Foundations
                Section(header: Text("Therapeutic Foundations")) {
                    NavigationLink(destination: LearningDetailView(
                        title: "Cognitive Behavioral Therapy (CBT)",
                        icon: "brain.head.profile",
                        content: """
                        **Cognitive Behavioral Therapy**
                        Cognitive behavioral therapy is a structured, evidence-based therapy treatment, based on the idea that psychological problems are based in part on negative thoughts patterns and behaviors. It employs various tactics to overcome these thoughts and behaviors, in order to mitigate the effects of said problems.
                        
                        **Tactics and Specifics**
                        One of the key issues targeted by CBT is anxiety of different forms. Anxiety is characterized by negative thought patterns and destructive behaviors that impact quality of life. Tactics to treat anxiety include but are not limited to:
                                                • Journaling - organizing negative thoughts, and writing down positive ones, can help process emotions and avoid feeling overwhelemd.
                                                • Breath exercises - controlled breathing and other meditative practices help calm the mind by reducing the body's stress response
                                                • Exposure - Facing fear in a controlled manner can reduce the magnitude of response over time
                        
                        
                        **Where Our App Fits**
                        This app acts as an "exposure companion", focusing specifically on tracking exposure sessions, and offering journaling, biostatistics, and historical growth data in one place. It can be used either independently or as a helper outside of regular therapy sessions in order to help you face and overcome your fears.
                        """
                    )) {
                        Label("What is CBT?", systemImage: "brain")
                    }
                    
                    NavigationLink(destination: LearningDetailView(
                        title: "Exposure Therapy",
                        icon: "figure.walk.motion",
                        content: """
                        **Exposure: Facing the Fear**
                        Exposure Therapy is a technique used in cognitive behavioral therapy designed to break the cycle of avoidance. When avoiding a scary situation, anxiety can go down temporarily, but long-term avoidance behaviors can lead to destructive behaviors, reduced quality of life, and an even greater level of fear. For example, continuous avoidance of social situations due to anxiety can lead to isolation, loneliness, sedentariness, and more, making it critical to break out of the cycle as soon as possible.
                        
                        **The Science: Habituation**
                        By staying in a feared situation without leaving or using "safety behaviors," your brain eventually learns that the danger isn't real. This natural drop in anxiety over time is called **Habituation**, and is a well studied concept in behavioral science. An exposure session will typically see a spike in initial anxiety levels, which then tapers off back to a baseline level as the session goes on - this shows the body physically adapting to the situation. Repeated over long periods of time, constant habituation can mitigate and even remove fears entirely.
                        
                        **Where Our App Fits**
                        This app helps track exposure sessions over time. We use your body's biomarkers as a proxy for physiological stress and anxiety, which can help us estimate your habituation levels during sessions. This way, it's possible to track how your mind and your body react to the same external stimuli over time. Additionally, we allow you to record your thoughts after each session, which may help to identify and internalize patterns of avoidance so you can slowly let them go.
                        """
                    )) {
                        Label("Exposure Therapy & Habituation", systemImage: "figure.walk")
                    }
                }
                
                // SECTION 2: Understanding Your Data
                Section(header: Text("Metrics Guide")) {
                    NavigationLink(destination: LearningDetailView(
                        title: "Subjective Units of Distress (SUDS)",
                        icon: "chart.bar.doc.horizontal",
                        content: """
                        **Measuring the Invisible**
                        We have you rate your experiences using subjective units of distress, or SUDS. It is a standard scale used by therapists to measure the intensity of distress. It helps you and your therapist track your progress over time. Basically, it's a self reported score on how comfortable or uncomfortable you **felt**.
                        
                        **The Scale:**
                                                • **0**: Totally relaxed / No distress
                                                • **25**: Mild anxiety
                                                • **50**: Uncomfortable but manageable
                                                • **75**: Severe anxiety
                                                • **100**: Highest anxiety imaginable / Panic
                        """
                    )) {
                        Label("Mental Stress (Mind)", systemImage: "chart.bar")
                    }
                    
                    NavigationLink(destination: LearningDetailView(
                        title: "Physiological Stress Score",
                        icon: "heart.text.square",
                        content: """
                        **Quantifying Arousal**
                        We calculate your "Physiological Stress" using the **Karvonen Formula**, which measures how much of your "Heart Rate Reserve" (HRR) you are currently using.
                        
                        **The Formula:**
                        `Intensity = (CHR - RHR) / (MHR - RHR)`
                        
                        **What it means:**
                        This scores simply contextualizes your current heart rate (CHR) within the range of your resting (RHR) and maximum (MHR) heart rates. A score of 50 indicates mild arousal, whether you're nervous, excited, or on a moderate jog. Higher scores indicate higher states of physiological stress: during anxiety monitoring, panicked behavior and nervousness can cause this score to jump up. Our app helps track and contextualize these moments for you.
                        """
                    )) {
                        Label("Physiological Stress (Body)", systemImage: "heart")
                    }
                    
                    // REPLACED SECTION: Focus on Progress/Habituation instead of Mind vs Body
                    NavigationLink(destination: LearningDetailView(
                        title: "Tracking Progress",
                        icon: "chart.line.uptrend.xyaxis",
                        content: """
                        **The Path to Improvement**
                        Recovery is not about eliminating anxiety overnight. It is about building tolerance and seeing your reactions change over time.
                        
                        **What to look for:**
                        
                        **1. Lower Peaks:**
                        Over repeated sessions, does your peak SUDS score (how scared you felt) drop?
                        
                        **2. Faster Recovery:**
                        Does your Body Score return to normal faster after the exposure ends?
                        
                        **3. Behavioral Change:**
                        Are you able to stay in the situation longer, or do it without safety behaviors?
                        
                        By tracking these metrics, you build a history of success that proves you are becoming stronger. 
                        """
                    )) {
                        Label("Tracking Your Progress", systemImage: "chart.xyaxis.line")
                    }
                }
            }
            .navigationTitle("Learning Center")
        }
    }
}

struct LearningDetailView: View {
    let title: String
    let icon: String
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Hero Section
                HStack {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: icon)
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                .padding(.bottom, 20)
                
                Divider()
                
                // 2. The Content
                // Using .init() to force Markdown parsing for bold text
                Text(.init(content))
                    .font(.body)
                    .lineSpacing(6)
                    .foregroundColor(Color.primary)
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
