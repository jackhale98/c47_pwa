(function() {
    'use strict';
    
    const performanceMetrics = {
        startTime: performance.now(),
        gtkLoadTime: null,
        firstInteraction: null,
        broadwayConnected: false,
        connectionAttempts: 0,
        maxConnectionAttempts: 5,
        frameLoadErrors: [],
        userAgent: navigator.userAgent,
        screenSize: `${screen.width}x${screen.height}`,
        viewport: `${window.innerWidth}x${window.innerHeight}`,
        deviceMemory: navigator.deviceMemory || 'unknown',
        connectionType: navigator.connection ? navigator.connection.effectiveType : 'unknown'
    };
    
    function logMetric(metricName, value, metadata = {}) {
        const metric = {
            name: metricName,
            value: value,
            timestamp: new Date().toISOString(),
            sessionId: getSessionId(),
            ...metadata
        };
        
        console.log(`📊 ${metricName}: ${value}`, metadata);
        
        if (typeof gtag !== 'undefined') {
            gtag('event', metricName, {
                value: Math.round(value),
                ...metadata
            });
        }
        
        try {
            const metrics = JSON.parse(localStorage.getItem('c47_metrics') || '[]');
            metrics.push(metric);
            if (metrics.length > 100) {
                metrics.shift();
            }
            localStorage.setItem('c47_metrics', JSON.stringify(metrics));
        } catch (e) {
            console.warn('Failed to store metric locally:', e);
        }
    }
    
    function getSessionId() {
        let sessionId = sessionStorage.getItem('c47_session_id');
        if (!sessionId) {
            sessionId = 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            sessionStorage.setItem('c47_session_id', sessionId);
        }
        return sessionId;
    }
    
    function monitorBroadwayConnection() {
        const gtkFrame = document.getElementById('gtk-frame');
        
        if (!gtkFrame) {
            console.warn('GTK frame not found, retrying in 1 second...');
            setTimeout(monitorBroadwayConnection, 1000);
            return;
        }
        
        gtkFrame.addEventListener('load', function() {
            performanceMetrics.gtkLoadTime = performance.now() - performanceMetrics.startTime;
            performanceMetrics.broadwayConnected = true;
            
            logMetric('gtk_broadway_loaded', performanceMetrics.gtkLoadTime, {
                user_agent: performanceMetrics.userAgent,
                screen_size: performanceMetrics.screenSize,
                connection_attempts: performanceMetrics.connectionAttempts
            });
            
            checkBroadwayPerformance();
        });
        
        gtkFrame.addEventListener('error', function(e) {
            performanceMetrics.connectionAttempts++;
            performanceMetrics.frameLoadErrors.push({
                timestamp: Date.now(),
                error: e.message || 'Unknown error'
            });
            
            console.error('❌ GTK Broadway connection failed:', e);
            
            logMetric('gtk_broadway_error', performanceMetrics.connectionAttempts, {
                error_type: 'connection_failed',
                user_agent: performanceMetrics.userAgent,
                attempt: performanceMetrics.connectionAttempts
            });
            
            if (performanceMetrics.connectionAttempts < performanceMetrics.maxConnectionAttempts) {
                console.log(`Retrying connection (${performanceMetrics.connectionAttempts}/${performanceMetrics.maxConnectionAttempts})...`);
                setTimeout(() => {
                    gtkFrame.src = gtkFrame.src;
                }, 2000 * performanceMetrics.connectionAttempts);
            } else {
                showConnectionError();
            }
        });
    }
    
    function checkBroadwayPerformance() {
        const observer = new PerformanceObserver((list) => {
            for (const entry of list.getEntries()) {
                if (entry.name.includes('broadway') || entry.name.includes('gtk')) {
                    logMetric('broadway_resource_timing', entry.duration, {
                        resource: entry.name,
                        transfer_size: entry.transferSize || 0,
                        encoded_size: entry.encodedBodySize || 0
                    });
                }
            }
        });
        
        observer.observe({ entryTypes: ['resource', 'navigation'] });
    }
    
    function showConnectionError() {
        const errorDiv = document.createElement('div');
        errorDiv.style.cssText = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: #f44336;
            color: white;
            padding: 20px;
            border-radius: 8px;
            z-index: 10000;
            text-align: center;
            box-shadow: 0 4px 20px rgba(0,0,0,0.3);
        `;
        errorDiv.innerHTML = `
            <h3>Connection Error</h3>
            <p>Unable to connect to GTK Broadway backend</p>
            <button onclick="location.reload()" style="
                background: white;
                color: #f44336;
                border: none;
                padding: 10px 20px;
                border-radius: 4px;
                cursor: pointer;
                margin-top: 10px;
            ">Retry</button>
        `;
        document.body.appendChild(errorDiv);
    }
    
    function trackFirstInteraction() {
        const interactionEvents = ['click', 'touchstart', 'keydown'];
        
        function recordInteraction(event) {
            if (!performanceMetrics.firstInteraction) {
                performanceMetrics.firstInteraction = performance.now() - performanceMetrics.startTime;
                
                logMetric('first_interaction', performanceMetrics.firstInteraction, {
                    interaction_type: event.type,
                    target_element: event.target.tagName,
                    broadway_connected: performanceMetrics.broadwayConnected
                });
                
                interactionEvents.forEach(evt => {
                    document.removeEventListener(evt, recordInteraction);
                });
            }
        }
        
        interactionEvents.forEach(event => {
            document.addEventListener(event, recordInteraction);
        });
    }
    
    function trackPWAInstallation() {
        let installPromptEvent = null;
        
        window.addEventListener('beforeinstallprompt', (e) => {
            e.preventDefault();
            installPromptEvent = e;
            
            logMetric('pwa_install_prompt_shown', 1, {
                user_agent: performanceMetrics.userAgent,
                platform: navigator.platform,
                viewport: performanceMetrics.viewport
            });
            
            showInstallButton(installPromptEvent);
        });
        
        window.addEventListener('appinstalled', (evt) => {
            logMetric('pwa_installed', 1, {
                user_agent: performanceMetrics.userAgent,
                platform: navigator.platform,
                install_source: 'browser_prompt'
            });
            
            hideInstallButton();
        });
    }
    
    function showInstallButton(installPromptEvent) {
        const installButton = document.createElement('button');
        installButton.id = 'pwa-install-button';
        installButton.style.cssText = `
            position: fixed;
            bottom: 20px;
            right: 20px;
            background: #4CAF50;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 24px;
            font-size: 16px;
            cursor: pointer;
            box-shadow: 0 2px 10px rgba(0,0,0,0.3);
            z-index: 9999;
            animation: pulse 2s infinite;
        `;
        installButton.textContent = '📱 Install App';
        
        installButton.addEventListener('click', async () => {
            if (installPromptEvent) {
                installPromptEvent.prompt();
                const { outcome } = await installPromptEvent.userChoice;
                
                logMetric('pwa_install_choice', outcome === 'accepted' ? 1 : 0, {
                    choice: outcome
                });
                
                if (outcome === 'accepted') {
                    hideInstallButton();
                }
            }
        });
        
        document.body.appendChild(installButton);
    }
    
    function hideInstallButton() {
        const button = document.getElementById('pwa-install-button');
        if (button) {
            button.remove();
        }
    }
    
    function monitorPWAPerformance() {
        if ('PerformanceObserver' in window) {
            try {
                const paintObserver = new PerformanceObserver((list) => {
                    for (const entry of list.getEntries()) {
                        logMetric(`pwa_${entry.name}`, entry.startTime, {
                            entry_type: entry.entryType
                        });
                    }
                });
                paintObserver.observe({ entryTypes: ['paint'] });
                
                const navigationObserver = new PerformanceObserver((list) => {
                    for (const entry of list.getEntries()) {
                        if (entry.entryType === 'navigation') {
                            const metrics = {
                                dns_lookup: entry.domainLookupEnd - entry.domainLookupStart,
                                tcp_connection: entry.connectEnd - entry.connectStart,
                                request_time: entry.responseStart - entry.requestStart,
                                response_time: entry.responseEnd - entry.responseStart,
                                dom_processing: entry.domComplete - entry.domInteractive,
                                load_complete: entry.loadEventEnd - entry.loadEventStart,
                                total_time: entry.loadEventEnd - entry.fetchStart
                            };
                            
                            Object.entries(metrics).forEach(([key, value]) => {
                                logMetric(`pwa_${key}`, value);
                            });
                        }
                    }
                });
                navigationObserver.observe({ entryTypes: ['navigation'] });
                
            } catch (e) {
                console.warn('Performance monitoring not fully supported:', e);
            }
        }
        
        if ('memory' in performance) {
            setInterval(() => {
                const memoryInfo = performance.memory;
                logMetric('pwa_memory_usage', memoryInfo.usedJSHeapSize, {
                    total_heap: memoryInfo.totalJSHeapSize,
                    heap_limit: memoryInfo.jsHeapSizeLimit
                });
            }, 30000);
        }
    }
    
    function trackCalculatorOperations() {
        document.addEventListener('click', function(e) {
            const target = e.target;
            
            if (target.classList.contains('calc-button') || 
                target.closest('.calc-button')) {
                const button = target.closest('.calc-button') || target;
                const operation = button.dataset.operation || button.textContent;
                
                logMetric('calculator_operation', 1, {
                    operation: operation,
                    button_type: button.dataset.type || 'unknown'
                });
            }
        });
    }
    
    function monitorNetworkStatus() {
        function updateNetworkStatus() {
            const isOnline = navigator.onLine;
            const connectionType = navigator.connection ? navigator.connection.effectiveType : 'unknown';
            
            logMetric('network_status_change', isOnline ? 1 : 0, {
                online: isOnline,
                connection_type: connectionType
            });
        }
        
        window.addEventListener('online', updateNetworkStatus);
        window.addEventListener('offline', updateNetworkStatus);
        
        if (navigator.connection) {
            navigator.connection.addEventListener('change', updateNetworkStatus);
        }
    }
    
    function sendAnalyticsBeacon() {
        window.addEventListener('beforeunload', function() {
            const sessionMetrics = {
                session_duration: performance.now(),
                gtk_connected: performanceMetrics.broadwayConnected,
                interactions: document.querySelectorAll('[data-interaction-tracked]').length,
                errors: performanceMetrics.frameLoadErrors.length
            };
            
            if (navigator.sendBeacon) {
                const data = new FormData();
                data.append('metrics', JSON.stringify(sessionMetrics));
                navigator.sendBeacon('/api/analytics/session-end', data);
            }
        });
    }
    
    function initializeAnalytics() {
        console.log('🎯 C47 PWA Analytics initialized');
        
        monitorBroadwayConnection();
        trackFirstInteraction();
        trackPWAInstallation();
        monitorPWAPerformance();
        trackCalculatorOperations();
        monitorNetworkStatus();
        sendAnalyticsBeacon();
        
        logMetric('analytics_initialized', 1, {
            user_agent: performanceMetrics.userAgent,
            screen_size: performanceMetrics.screenSize,
            device_memory: performanceMetrics.deviceMemory,
            connection_type: performanceMetrics.connectionType
        });
    }
    
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializeAnalytics);
    } else {
        initializeAnalytics();
    }
    
    window.C47Analytics = {
        logMetric: logMetric,
        getMetrics: () => performanceMetrics,
        getSessionId: getSessionId
    };
    
})();