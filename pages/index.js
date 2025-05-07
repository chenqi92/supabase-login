import { useEffect } from 'react';
import { useRouter } from 'next/router';

export default function Home() {
  const router = useRouter();

  useEffect(() => {
    // 重定向到登录页面
    router.push('/login');
  }, []);

  return (
    <div>
      <h1>正在重定向到登录页面...</h1>
    </div>
  );
} 