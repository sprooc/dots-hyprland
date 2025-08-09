pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules.common

Singleton {
    id: root
    
    // Check for updates every configured interval
    readonly property int checkInterval: Config.options.bar.aur.checkInterval * 60 * 1000
    
    property var data: ({
        updateCount: 0,
        updating: false,
        lastCheck: new Date()
    })

    function checkUpdates() {
        root.data = {
            updateCount: root.data.updateCount,
            updating: true,
            lastCheck: root.data.lastCheck
        };
        // Use yay to check for AUR updates
        let command = "yay -Qu | wc -l";
        fetcher.command[2] = command;
        fetcher.running = true;
    }

    function formatLastCheck() {
        const now = new Date();
        const diff = Math.floor((now - root.data.lastCheck) / 1000); // seconds
        
        if (diff < 60) {
            return "just now";
        } else if (diff < 3600) {
            const minutes = Math.floor(diff / 60);
            return `${minutes}m ago`;
        } else if (diff < 86400) {
            const hours = Math.floor(diff / 3600);
            return `${hours}h ago`;
        } else {
            const days = Math.floor(diff / 86400);
            return `${days}d ago`;
        }
    }

    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const count = parseInt(text.trim()) || 0;
                    root.data = {
                        updateCount: count,
                        updating: false,
                        lastCheck: new Date()
                    };
                    console.info(`[AurUpdates] Found ${count} available updates`);
                } catch (e) {
                    console.error(`[AurUpdates] ${e.message}`);
                    root.data = {
                        updateCount: root.data.updateCount,
                        updating: false,
                        lastCheck: root.data.lastCheck
                    };
                }
            }
        }
        
        onExited: {
            root.data = {
                updateCount: root.data.updateCount,
                updating: false,
                lastCheck: root.data.lastCheck
            };
        }
    }

    Timer {
        running: Config.options.bar.aur.enable
        repeat: true
        interval: root.checkInterval
        triggeredOnStart: Config.options.bar.aur.enable
        onTriggered: root.checkUpdates()
    }
}
