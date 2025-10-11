// Supabase Configuration
const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Office Location Configuration (Riyadh coordinates as default)
const OFFICE_LOCATION = {
    latitude: 24.429328,
    longitude: 39.653926,
    radius: 50000, // meters - نطاق أصغر للدقة
    name: 'المكتب الرئيسي'
};

// Initialize Supabase client
let supabase = null;

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    if (window.supabase && window.supabase.createClient) {
        supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
            auth: {
                autoRefreshToken: true,
                persistSession: true,
                detectSessionInUrl: false
            }
        });
        console.log('تم تحميل Supabase بنجاح');
    } else {
        console.error('فشل في تحميل مكتبة Supabase');
    }
});
