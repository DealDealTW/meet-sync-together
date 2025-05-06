
import React, { createContext, useState, useContext, useEffect } from "react";
import { nanoid } from "nanoid";

interface UserContextType {
  userId: string;
  userName: string;
  setUserName: (name: string) => void;
  userEvents: string[];
  addUserEvent: (eventId: string) => void;
}

const UserContext = createContext<UserContextType | undefined>(undefined);

export const UserProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [userId, setUserId] = useState<string>("");
  const [userName, setUserName] = useState<string>("");
  const [userEvents, setUserEvents] = useState<string[]>([]);

  useEffect(() => {
    // Load or create user ID
    const storedUserId = localStorage.getItem("userId");
    if (storedUserId) {
      setUserId(storedUserId);
    } else {
      const newUserId = nanoid();
      setUserId(newUserId);
      localStorage.setItem("userId", newUserId);
    }

    // Load username if available
    const storedUserName = localStorage.getItem("userName");
    if (storedUserName) {
      setUserName(storedUserName);
    }

    // Load user events
    const storedEvents = localStorage.getItem("userEvents");
    if (storedEvents) {
      setUserEvents(JSON.parse(storedEvents));
    }
  }, []);

  // Save username when it changes
  useEffect(() => {
    if (userName) {
      localStorage.setItem("userName", userName);
    }
  }, [userName]);

  // Save user events when they change
  useEffect(() => {
    if (userEvents.length > 0) {
      localStorage.setItem("userEvents", JSON.stringify(userEvents));
    }
  }, [userEvents]);

  const addUserEvent = (eventId: string) => {
    if (!userEvents.includes(eventId)) {
      setUserEvents([...userEvents, eventId]);
    }
  };

  const value = {
    userId,
    userName,
    setUserName,
    userEvents,
    addUserEvent,
  };

  return <UserContext.Provider value={value}>{children}</UserContext.Provider>;
};

export const useUser = (): UserContextType => {
  const context = useContext(UserContext);
  if (context === undefined) {
    throw new Error("useUser must be used within a UserProvider");
  }
  return context;
};
