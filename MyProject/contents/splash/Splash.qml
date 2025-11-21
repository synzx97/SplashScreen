import QtQuick 2.7
import QtMultimedia 5.9
import QtGraphicalEffects 1.0

Item {
    id: root
    width: 1280
    height: 720
    
    // Timing controls
    property int stage: 0
    property real phase1Duration: 2.5  // logo + loading phase (detik)
    property real phase2Duration: 3.0  // video phase (detik)
    property real transitionDuration: 0.8  // durasi transisi antar fase (detik)
    
    // Background hitam solid
    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }
    
    // ==================== PHASE 1: Logo + Loading ====================
    Item {
        id: phase1Container
        anchors.fill: parent
        opacity: 1.0
        scale: 1.0
        
        // Logo centered
        Image {
            id: logo
            source: "images/logo.png"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -40
            width: Math.min(root.width, root.height) * 0.25
            height: width
            smooth: true
            antialiasing: true
            opacity: 0
            scale: 0.9
            transformOrigin: Item.Center
        }
        
        // Progress bar container
        Item {
            id: progressContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo.bottom
            anchors.topMargin: 50
            width: root.width * 0.4
            height: 40
            opacity: 0
            
            // Progress track
            Rectangle {
                id: progressTrack
                width: parent.width
                height: 4
                anchors.centerIn: parent
                color: "#ffffff"
                opacity: 0.15
                radius: 2
            }
            
            // Progress fill
            Rectangle {
                id: progressFill
                height: 4
                anchors.left: progressTrack.left
                anchors.verticalCenter: progressTrack.verticalCenter
                width: 0
                radius: 2
                color: "#ffffff"
                opacity: 0.9
                
                Behavior on width {
                    NumberAnimation { 
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
            }
            
            // Loading text
            Text {
                id: loadingText
                text: "Loading"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: progressTrack.top
                anchors.bottomMargin: 12
                color: "#ffffff"
                font.pixelSize: 14
                font.letterSpacing: 2
                opacity: 0.7
                
                SequentialAnimation on opacity {
                    running: phase1Container.opacity > 0
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.4; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.0; to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                }
            }
        }
        
        // Blur effect untuk transisi
        layer.enabled: true
        layer.effect: FastBlur {
            id: phase1Blur
            radius: 0
            transparentBorder: true
            
            Behavior on radius {
                NumberAnimation { 
                    duration: transitionDuration * 1000
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
    
    // ==================== PHASE 2: Video ====================
    Item {
        id: phase2Container
        anchors.fill: parent
        opacity: 0
        scale: 1.2
        
        MediaPlayer {
            id: player
            source: "media/video.mp4"
            autoPlay: false
            muted: true
            volume: 0.0
            
            onStatusChanged: {
                if (status === MediaPlayer.EndOfMedia) {
                    console.log("Video finished naturally")
                    finishSplash()
                }
            }
            
            onError: {
                console.log("MediaPlayer error:", errorString)
                // Fallback: langsung finish jika video error
                finishSplash()
            }
        }
        
        VideoOutput {
            id: videoOut
            anchors.fill: parent
            source: player
            fillMode: VideoOutput.PreserveAspectCrop
        }
        
        // Blur effect untuk transisi
        layer.enabled: true
        layer.effect: FastBlur {
            id: phase2Blur
            radius: 32
            transparentBorder: true
            
            Behavior on radius {
                NumberAnimation { 
                    duration: transitionDuration * 1000
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
    
    // ==================== ANIMATIONS ====================
    
    // Phase 1: Logo fade in + scale
    ParallelAnimation {
        id: logoIntroAnim
        NumberAnimation {
            target: logo
            property: "opacity"
            from: 0
            to: 1
            duration: 800
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: logo
            property: "scale"
            from: 0.9
            to: 1.0
            duration: 800
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }
    
    // Progress bar fade in
    NumberAnimation {
        id: progressFadeIn
        target: progressContainer
        property: "opacity"
        from: 0
        to: 1
        duration: 600
        easing.type: Easing.OutCubic
    }
    
    // Transition: Phase 1 -> Phase 2
    ParallelAnimation {
        id: transitionToVideo
        
        // Phase 1: Scale up + fade out + blur
        ParallelAnimation {
            NumberAnimation {
                target: phase1Container
                property: "opacity"
                to: 0
                duration: transitionDuration * 1000
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: phase1Container
                property: "scale"
                to: 1.15
                duration: transitionDuration * 1000
                easing.type: Easing.InOutQuad
            }
            ScriptAction {
                script: phase1Blur.radius = 32
            }
        }
        
        // Phase 2: Scale in + fade in + unblur
        ParallelAnimation {
            NumberAnimation {
                target: phase2Container
                property: "opacity"
                to: 1
                duration: transitionDuration * 1000
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: phase2Container
                property: "scale"
                from: 1.2
                to: 1.0
                duration: transitionDuration * 1000
                easing.type: Easing.OutCubic
            }
            ScriptAction {
                script: phase2Blur.radius = 0
            }
        }
        
        onStarted: {
            console.log("Starting transition to video")
            player.play()
        }
    }
    
    // Final fade out
    NumberAnimation {
        id: finalFadeOut
        target: root
        property: "opacity"
        to: 0
        duration: 600
        easing.type: Easing.InOutQuad
    }
    
    // ==================== TIMERS ====================
    
    // Progress bar animation
    Timer {
        id: progressTimer
        interval: 50
        repeat: true
        running: false
        property real progress: 0
        
        onTriggered: {
            progress += 50 / (phase1Duration * 1000)
            if (progress >= 1.0) {
                progress = 1.0
                running = false
            }
            progressFill.width = progressTrack.width * progress
        }
    }
    
    // Phase 1 timer
    Timer {
        id: phase1Timer
        interval: phase1Duration * 1000
        running: false
        repeat: false
        onTriggered: {
            console.log("Phase 1 complete, transitioning to video")
            transitionToVideo.start()
        }
    }
    
    // Phase 2 timer (auto-stop video)
    Timer {
        id: phase2Timer
        interval: phase2Duration * 1000
        running: false
        repeat: false
        onTriggered: {
            console.log("Phase 2 complete, finishing splash")
            finishSplash()
        }
    }
    
    // ==================== FUNCTIONS ====================
    
    function startPhase1() {
        console.log("Starting Phase 1: Logo + Loading")
        logoIntroAnim.start()
        
        // Delay progress bar untuk lebih natural
        progressFadeInTimer.start()
    }
    
    Timer {
        id: progressFadeInTimer
        interval: 400
        running: false
        repeat: false
        onTriggered: {
            progressFadeIn.start()
            progressTimer.progress = 0
            progressTimer.start()
            phase1Timer.start()
        }
    }
    
    function finishSplash() {
        console.log("Finishing splash screen")
        player.stop()
        phase2Timer.running = false
        finalFadeOut.start()
    }
    
    // ==================== PLASMA STAGE CONTROL ====================
    
    onStageChanged: {
        console.log("Stage changed to:", stage)
        if (stage === 1) {
            startPhase1()
        }
        if (stage >= 5) {
            finishSplash()
        }
    }
    
    // ==================== DEBUG MODE ====================
    
    // Auto-start untuk qmlscene testing
    Timer {
        id: debugAutoStart
        interval: 500
        running: true
        repeat: false
        onTriggered: {
            console.log("=== DEBUG MODE: Auto-starting splash ===")
            startPhase1()
        }
    }
    
    // Click to skip phases
    MouseArea {
        anchors.fill: parent
        onClicked: {
            console.log("Click detected - skipping current phase")
            if (phase1Timer.running) {
                phase1Timer.stop()
                progressTimer.stop()
                transitionToVideo.start()
            } else if (phase2Timer.running) {
                finishSplash()
            }
        }
    }
    
    Component.onCompleted: {
        console.log("=== Elegant Video Splash Screen Initialized ===")
        console.log("Phase 1 duration:", phase1Duration, "seconds")
        console.log("Phase 2 duration:", phase2Duration, "seconds")
        console.log("Transition duration:", transitionDuration, "seconds")
    }
}
