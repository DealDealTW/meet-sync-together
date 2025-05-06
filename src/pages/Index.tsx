
import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { Plus, Calendar, CalendarCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import Header from "@/components/Header";
import { getEvents } from "@/services/EventService";
import { Event } from "@/models/EventModel";
import { format, parseISO } from "date-fns";
import { useUser } from "@/contexts/UserContext";

const Index = () => {
  const [events, setEvents] = useState<Event[]>([]);
  const { userName, userEvents } = useUser();
  
  useEffect(() => {
    const storedEvents = getEvents();
    setEvents(storedEvents);
  }, []);

  const formatDate = (dateStr: string) => {
    try {
      const date = parseISO(dateStr);
      return format(date, "MMM d, yyyy");
    } catch (e) {
      return dateStr;
    }
  };

  const isUserEvent = (eventId: string) => {
    return userEvents.includes(eventId);
  };

  return (
    <div className="mobile-container pb-20">
      <Header title="MeetSync" />
      
      <main className="p-4 space-y-6">
        {/* Welcome Message */}
        <section className="text-center space-y-2 py-6">
          <h1 className="text-3xl font-bold">
            Find the best time to meet
          </h1>
          <p className="text-muted-foreground">
            Create events and coordinate with friends easily
          </p>
        </section>

        {/* Create Event Button */}
        <section className="flex justify-center">
          <Link to="/create">
            <Button size="lg" className="shadow-md flex gap-2 h-14 px-8 rounded-full">
              <Plus size={20} />
              <span>Create Event</span>
            </Button>
          </Link>
        </section>

        {/* User's Events */}
        <section className="space-y-4 pt-4">
          <h2 className="text-xl font-semibold flex items-center gap-2">
            <CalendarCheck size={20} /> Your Events
          </h2>
          
          {events.filter(event => isUserEvent(event.id)).length > 0 ? (
            <div className="space-y-3">
              {events
                .filter(event => isUserEvent(event.id))
                .map(event => (
                  <Link to={`/event/${event.id}`} key={event.id}>
                    <Card className="hover:shadow-md transition-all">
                      <CardHeader className="pb-2">
                        <CardTitle className="text-lg">{event.title}</CardTitle>
                        <CardDescription>
                          {event.timeOptions.length} time options · {event.attendees.length} responses
                        </CardDescription>
                      </CardHeader>
                      <CardContent>
                        <p className="text-sm text-muted-foreground">
                          Created on {formatDate(event.createdAt)}
                        </p>
                      </CardContent>
                    </Card>
                  </Link>
                ))}
            </div>
          ) : (
            <div className="text-center py-8 text-muted-foreground">
              <Calendar className="mx-auto h-12 w-12 opacity-20 mb-2" />
              <p>You haven't created any events yet</p>
            </div>
          )}
        </section>
      </main>
    </div>
  );
};

export default Index;
