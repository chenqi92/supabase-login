import { LoginForm } from "@/components/auth/login-form";

export default function LoginPage() {
  return (
    <div className="container relative h-screen flex-col items-center justify-center grid lg:max-w-none lg:grid-cols-2 lg:px-0">
      <div className="relative hidden h-full flex-col bg-muted p-10 text-white lg:flex dark:border-r">
        <div className="absolute inset-0 bg-zinc-900">
          <div className="absolute inset-0 bg-gradient-to-br from-supabase/20 via-supabase/10 to-transparent" />
        </div>
        <div className="relative z-20 flex items-center text-lg font-medium">
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            className="mr-2 h-6 w-6"
          >
            <path
              d="M12.0001 1C14.3874 1 16.5381 1.99867 18.0846 3.6154C17.7367 3.84082 17.4326 4.11181 17.1834 4.42476L15.4101 6.58467C14.7008 5.91705 13.7558 5.52246 12.7269 5.52246C10.7641 5.52246 9.17651 7.11005 9.17651 9.0729C9.17651 10.1018 9.5711 11.0468 10.2387 11.7561L8.07882 13.5294C7.76586 13.7786 7.49487 14.0827 7.26945 14.4306C5.65273 12.8841 4.65405 10.7334 4.65405 8.34608C4.65405 4.2478 7.90181 1 12.0001 1Z"
              fill="#3ECF8E"
            />
            <path
              d="M12.0001 15.1694C14.0922 15.1694 15.7843 13.4774 15.7843 11.3853C15.7843 9.29317 14.0922 7.60107 12.0001 7.60107C9.90796 7.60107 8.21586 9.29317 8.21586 11.3853C8.21586 13.4774 9.90796 15.1694 12.0001 15.1694Z"
              fill="#3ECF8E"
            />
            <path
              d="M18.0845 20.3846C16.538 22.0013 14.3873 23 11.9999 23C7.90171 23 4.65395 19.7522 4.65395 15.6539C4.65395 13.2666 5.65262 11.1159 7.26934 9.56937L9.42923 11.3427C8.76161 12.052 8.36702 12.997 8.36702 14.0259C8.36702 15.9887 9.95461 17.5763 11.9175 17.5763C12.9463 17.5763 13.8913 17.1817 14.6007 16.5141L16.374 18.674C16.6232 18.987 16.9273 19.258 17.2751 19.4834C17.526 19.705 17.8 19.9032 18.0845 20.0741V20.3846Z"
              fill="#3ECF8E"
            />
          </svg>
          Supabase
        </div>
        <div className="relative z-20 mt-auto">
          <blockquote className="space-y-2">
            <p className="text-lg">
              &ldquo;Supabase 是一个优秀的开源平台，让你能够快速构建现代化的、安全的应用。&rdquo;
            </p>
            <footer className="text-sm">Supabase Team</footer>
          </blockquote>
        </div>
      </div>
      <div className="lg:p-8">
        <div className="mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]">
          <LoginForm />
        </div>
      </div>
    </div>
  );
} 