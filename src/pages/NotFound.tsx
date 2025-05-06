
import { Button } from "@/components/ui/button";
import { useLocation, useNavigate } from "react-router-dom";
import { useEffect } from "react";

const NotFound = () => {
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    console.error("404 Error: User attempted to access non-existent route:", location.pathname);
  }, [location.pathname]);

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-background p-4 text-center">
      <div className="space-y-6 max-w-md">
        <h1 className="text-6xl font-bold text-primary">404</h1>
        <p className="text-xl">Oops! We can't find that page</p>
        <p className="text-muted-foreground">
          The page you're looking for might have been moved or doesn't exist.
        </p>
        <Button onClick={() => navigate("/")} size="lg">
          Go back home
        </Button>
      </div>
    </div>
  );
};

export default NotFound;
