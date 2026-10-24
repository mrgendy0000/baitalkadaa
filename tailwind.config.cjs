
        module.exports = {
            theme: {
                extend: {
                    colors: {
                        odoo: {
                            purple: '#714B67',
                            'purple-dark': '#53364C',
                            'purple-light': '#8A5C7E',
                            'purple-tint': '#F3EEF2',
                            teal: '#00A09D',
                            'teal-dark': '#017E84',
                            'teal-light': '#E6F6F6',
                            bg: '#FFFFFF',
                            'bg-subtle': '#F8F9FA',
                            line: '#E9ECEF',
                            ink: '#212529',
                            muted: '#6C757D'
                        },
                        navy: {
                            50: '#F8FAFA',
                            100: '#F3EEF2',
                            200: '#E9ECEF',
                            700: '#53364C',
                            800: '#714B67',
                            900: '#53364C',
                            950: '#351E30',
                        },
                        gold: {
                            50: '#FEF9EE',
                            100: '#FDF1D6',
                            200: '#FBDFA8',
                            400: '#F59E0B',
                            500: '#D97706',
                            600: '#B45309',
                            700: '#92400E',
                        }
                    },
                    fontFamily: {
                        cairo: ['Tajawal', 'Cairo', 'sans-serif'],
                        tajawal: ['Tajawal', 'Readex Pro', 'sans-serif'],
                        amiri: ['Amiri', 'serif'],
                    }
                }
            }
        }
    
module.exports.content=['./app.html','./static/assistant.js','./static/launch.js'];
