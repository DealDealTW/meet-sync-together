
import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { format, parseISO } from "date-fns";
import { Button } from "@/components/ui/button";
import { Calendar, Check, Share2, Copy, Users, MapPin } from "lucide-react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import Header from "@/components/Header";
import TimeSlot from "@/components/TimeSlot";
import { getEventById, addAttendee } from "@/services/EventService";
import { Event, findBestTimeOptions, TimeOption } from "@/models/EventModel";
import { useUser } from "@/contexts/UserContext";
import { toast } from "sonner";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";

const EventDetails = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { userId, userName, setUserName } = useUser();
  
  const [event, setEvent] = useState<Event | null>(null);
  const [loading, setLoading] = useState(true);
  const [name, setName] = useState(userName || "");
  const [comment, setComment] = useState("");
  const [selectedTimeIds, setSelectedTimeIds] = useState<string[]>([]);
  const [bestTimeOptions, setBestTimeOptions] = useState<TimeOption[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [activeTab, setActiveTab] = useState("availability");
  
  useEffect(() => {
    if (!id) return;
    
    const fetchEvent = () => {
      const eventData = getEventById(id);
      if (eventData) {
        setEvent(eventData);
        setBestTimeOptions(findBestTimeOptions(eventData));
      } else {
        toast.error("Event not found");
        navigate("/");
      }
      setLoading(false);
    };
    
    fetchEvent();
  }, [id, navigate]);
  
  const toggleTimeSlot = (timeId: string) => {
    setSelectedTimeIds(prev => 
      prev.includes(timeId)
        ? prev.filter(id => id !== timeId)
        : [...prev, timeId]
    );
  };
  
  const handleSubmitResponse = () => {
    if (!event || !id) return;
    
    if (!name.trim()) {
      toast.error("Please enter your name");
      return;
    }
    
    if (selectedTimeIds.length === 0) {
      toast.error("Please select at least one time slot");
      return;
    }
    
    setIsSubmitting(true);
    
    // Save name for future use
    if (name !== userName) {
      setUserName(name);
    }
    
    // Add response to event
    const updatedEvent = addAttendee(id, name, selectedTimeIds, comment);
    
    if (updatedEvent) {
      setEvent(updatedEvent);
      setBestTimeOptions(findBestTimeOptions(updatedEvent));
      setSelectedTimeIds([]);
      setComment("");
      setActiveTab("results");
    }
    
    setIsSubmitting(false);
  };
  
  const copyEventLink = () => {
    const url = window.location.href;
    navigator.clipboard.writeText(url);
    toast.success("Link copied to clipboard");
  };
  
  const formatDate = (dateStr: string) => {
    try {
      const date = parseISO(dateStr);
      return format(date, "EEE, MMM d");
    } catch (e) {
      return dateStr;
    }
  };
  
  const formatTime = (timeStr: string) => {
    try {
      const time = parseISO(timeStr);
      return format(time, "h:mm a");
    } catch (e) {
      return timeStr;
    }
  };
  
  const getAttendeesForTimeSlot = (timeSlotId: string) => {
    if (!event) return [];
    
    return event.attendees
      .filter(attendee => attendee.selectedTimeIds.includes(timeSlotId))
      .map(attendee => attendee.name);
  };

  if (loading) {
    return (
      <div className="mobile-container flex items-center justify-center h-screen">
        <div className="text-center space-y-4">
          <div className="w-12 h-12 rounded-full border-4 border-t-primary animate-spin mx-auto"></div>
          <p className="text-muted-foreground">Loading event...</p>
        </div>
      </div>
    );
  }
  
  if (!event) {
    return (
      <div className="mobile-container flex items-center justify-center h-screen">
        <div className="text-center space-y-4">
          <p className="text-xl">Event not found</p>
          <Button onClick={() => navigate("/")}>Back to Home</Button>
        </div>
      </div>
    );
  }

  return (
    <div className="mobile-container pb-20">
      <Header title="Event Details" />
      
      <main className="p-4 space-y-6">
        {/* Event Header */}
        <section className="space-y-2">
          <h1 className="text-2xl font-bold">{event.title}</h1>
          
          {event.description && (
            <p className="text-muted-foreground">{event.description}</p>
          )}
          
          <div className="flex flex-wrap gap-3 mt-2">
            {event.location && (
              <div className="flex items-center gap-1 text-sm text-muted-foreground">
                <MapPin size={16} />
                <span>{event.location}</span>
              </div>
            )}
            
            <div className="flex items-center gap-1 text-sm text-muted-foreground">
              <Users size={16} />
              <span>{event.attendees.length} responses</span>
            </div>
          </div>
        </section>
        
        {/* Share Button */}
        <Button 
          variant="outline" 
          className="w-full flex gap-2"
          onClick={copyEventLink}
        >
          <Share2 size={18} />
          <span>Share Event</span>
        </Button>
        
        {/* Tabs */}
        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
          <TabsList className="grid grid-cols-3 w-full">
            <TabsTrigger value="availability">Respond</TabsTrigger>
            <TabsTrigger value="results">Best Times</TabsTrigger>
            <TabsTrigger value="attendees">Responses</TabsTrigger>
          </TabsList>
          
          {/* Availability Tab */}
          <TabsContent value="availability" className="space-y-4">
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="name">Your Name</Label>
                <Input
                  id="name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Enter your name"
                />
              </div>
              
              <div className="space-y-2">
                <Label>Select times you're available</Label>
                <div className="space-y-2">
                  {event.timeOptions.map((option) => (
                    <TimeSlot
                      key={option.id}
                      timeSlot={option}
                      isSelected={selectedTimeIds.includes(option.id)}
                      onToggle={toggleTimeSlot}
                    />
                  ))}
                </div>
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="comment">Comment (Optional)</Label>
                <Textarea
                  id="comment"
                  value={comment}
                  onChange={(e) => setComment(e.target.value)}
                  placeholder="Add a comment..."
                  rows={3}
                />
              </div>
              
              <Button 
                onClick={handleSubmitResponse} 
                disabled={isSubmitting}
                className="w-full"
              >
                Submit Response
              </Button>
            </div>
          </TabsContent>
          
          {/* Results Tab */}
          <TabsContent value="results" className="space-y-4">
            <div className="space-y-4">
              <h3 className="text-lg font-semibold">Best Times to Meet</h3>
              
              {bestTimeOptions.length > 0 ? (
                <div className="space-y-3">
                  {bestTimeOptions.map((option) => (
                    <Card key={option.id} className="border-primary/50 bg-primary/5">
                      <CardHeader className="pb-2">
                        <CardTitle className="text-base flex items-center gap-2">
                          <Check size={18} className="text-primary" />
                          {formatDate(option.date)}
                        </CardTitle>
                        <CardDescription>
                          {formatTime(option.startTime)} - {formatTime(option.endTime)}
                        </CardDescription>
                      </CardHeader>
                      <CardContent>
                        <div className="flex flex-wrap gap-1">
                          {getAttendeesForTimeSlot(option.id).map((name, idx) => (
                            <span 
                              key={idx} 
                              className="inline-flex text-xs py-0.5 px-2 rounded-full bg-primary/15 text-primary-foreground"
                            >
                              {name}
                            </span>
                          ))}
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              ) : (
                <div className="text-center py-8 text-muted-foreground">
                  <Calendar className="mx-auto h-12 w-12 opacity-20 mb-2" />
                  <p>No responses yet</p>
                  <p className="text-sm mt-1">Share this event to collect responses</p>
                </div>
              )}
              
              <Button
                variant="outline"
                className="w-full flex items-center justify-center gap-2"
                onClick={() => setActiveTab("availability")}
              >
                Submit Your Availability
              </Button>
            </div>
          </TabsContent>
          
          {/* Attendees Tab */}
          <TabsContent value="attendees" className="space-y-4">
            <div className="space-y-4">
              <h3 className="text-lg font-semibold">Responses ({event.attendees.length})</h3>
              
              {event.attendees.length > 0 ? (
                <div className="space-y-3">
                  {event.attendees.map((attendee) => (
                    <Card key={attendee.id}>
                      <CardHeader className="pb-2">
                        <CardTitle className="text-base">{attendee.name}</CardTitle>
                        <CardDescription>
                          Available for {attendee.selectedTimeIds.length} time slots
                        </CardDescription>
                      </CardHeader>
                      {attendee.comment && (
                        <CardContent>
                          <p className="text-sm italic">{attendee.comment}</p>
                        </CardContent>
                      )}
                    </Card>
                  ))}
                </div>
              ) : (
                <div className="text-center py-8 text-muted-foreground">
                  <Users className="mx-auto h-12 w-12 opacity-20 mb-2" />
                  <p>No responses yet</p>
                  <p className="text-sm mt-1">Share this event to collect responses</p>
                </div>
              )}
            </div>
          </TabsContent>
        </Tabs>
      </main>
    </div>
  );
};

export default EventDetails;
