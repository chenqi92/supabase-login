import { createClient } from '@supabase/supabase-js';

// 创建Supabase客户端 - 映射实际环境变量
export const createSupabaseClient = () => {
  // 使用NEXT_PUBLIC_前缀的变量，这些变量在构建时已从实际的Supabase环境变量映射
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://database.allbs.cn';
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';
  
  return createClient(supabaseUrl, supabaseKey, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
      flowType: 'pkce',
    },
  });
}; 