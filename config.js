// Supabase Configuration
const SUPABASE_URL = 'https://lkxdaoningeoqxhiuwtg.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxreGRhb25pbmdlb3F4aGl1d3RnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAxODA3MjAsImV4cCI6MjA3NTc1NjcyMH0.twIn987a2hw7_gf1gFZIzOxZRB8JaT2IHGePOBUL2DY';

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
