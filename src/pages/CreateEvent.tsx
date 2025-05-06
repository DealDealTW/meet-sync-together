
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { format } from "date-fns";
import { Plus, Trash2, CalendarIcon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Calendar } from "@/components/ui/calendar";
import Header from "@/components/Header";
import { createEvent } from "@/services/EventService";
import { useUser } from "@/contexts/UserContext";
import { toast } from "sonner";
import { cn } from "@/lib/utils";

interface TimeSlot {
  date: Date;
  startTime: string;
  endTime: string;
}

const CreateEvent = () => {
  const navigate = useNavigate();
  const { userId, userName, addUserEvent } = useUser();
  
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [location, setLocation] = useState("");
  const [timeSlots, setTimeSlots] = useState<TimeSlot[]>([
    { date: new Date(), startTime: "09:00", endTime: "10:00" }
  ]);
  
  const [selectedDate, setSelectedDate] = useState<Date | undefined>(new Date());
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleAddTimeSlot = () => {
    setTimeSlots([
      ...timeSlots,
      { date: new Date(), startTime: "09:00", endTime: "10:00" }
    ]);
  };

  const handleRemoveTimeSlot = (index: number) => {
    if (timeSlots.length > 1) {
      setTimeSlots(timeSlots.filter((_, i) => i !== index));
    } else {
      toast.error("You need at least one time slot");
    }
  };

  const handleTimeSlotChange = (index: number, field: keyof TimeSlot, value: any) => {
    const updatedSlots = [...timeSlots];
    updatedSlots[index] = { ...updatedSlots[index], [field]: value };
    setTimeSlots(updatedSlots);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    
    if (!title.trim()) {
      toast.error("Please provide an event title");
      setIsSubmitting(false);
      return;
    }
    
    if (timeSlots.length === 0) {
      toast.error("Please add at least one time slot");
      setIsSubmitting(false);
      return;
    }
    
    // Format time slots for API
    const formattedTimeSlots = timeSlots.map(slot => ({
      date: format(slot.date, "yyyy-MM-dd"),
      startTime: `${format(slot.date, "yyyy-MM-dd")}T${slot.startTime}:00`,
      endTime: `${format(slot.date, "yyyy-MM-dd")}T${slot.endTime}:00`
    }));
    
    // Create the event
    const name = userName || "Anonymous";
    const event = createEvent(title, description, location, name, formattedTimeSlots);
    
    if (event) {
      addUserEvent(event.id);
      navigate(`/event/${event.id}`);
    }
    
    setIsSubmitting(false);
  };

  return (
    <div className="mobile-container pb-20">
      <Header title="Create Event" />
      
      <main className="p-4">
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Event Title */}
          <div className="space-y-2">
            <Label htmlFor="title">Event Title *</Label>
            <Input
              id="title"
              placeholder="Dinner with friends, Team meeting, etc."
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
            />
          </div>
          
          {/* Event Description */}
          <div className="space-y-2">
            <Label htmlFor="description">Description (Optional)</Label>
            <Textarea
              id="description"
              placeholder="Add more details about your event..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
            />
          </div>
          
          {/* Location */}
          <div className="space-y-2">
            <Label htmlFor="location">Location (Optional)</Label>
            <Input
              id="location"
              placeholder="Restaurant name, address, or online link"
              value={location}
              onChange={(e) => setLocation(e.target.value)}
            />
          </div>
          
          {/* Time Slots */}
          <div className="space-y-4">
            <Label>Time Options *</Label>
            
            {timeSlots.map((slot, index) => (
              <div key={index} className="flex flex-col gap-3 p-3 border rounded-lg bg-card">
                <div className="flex justify-between">
                  <h3 className="text-sm font-medium">Option {index + 1}</h3>
                  
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => handleRemoveTimeSlot(index)}
                    className="h-8 w-8 p-0 rounded-full"
                  >
                    <Trash2 size={16} />
                  </Button>
                </div>
                
                <div className="space-y-3">
                  {/* Date picker */}
                  <div className="grid gap-2">
                    <Label htmlFor={`date-${index}`} className="text-xs">Date</Label>
                    <Popover>
                      <PopoverTrigger asChild>
                        <Button
                          id={`date-${index}`}
                          variant="outline"
                          className={cn(
                            "justify-start text-left font-normal",
                            !slot.date && "text-muted-foreground"
                          )}
                        >
                          <CalendarIcon className="mr-2 h-4 w-4" />
                          {slot.date ? format(slot.date, "PPP") : "Select date"}
                        </Button>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto p-0" align="start">
                        <Calendar
                          mode="single"
                          selected={slot.date}
                          onSelect={(date) => handleTimeSlotChange(index, "date", date || new Date())}
                          initialFocus
                        />
                      </PopoverContent>
                    </Popover>
                  </div>
                  
                  {/* Time range */}
                  <div className="grid grid-cols-2 gap-2">
                    <div className="space-y-2">
                      <Label htmlFor={`start-${index}`} className="text-xs">Start Time</Label>
                      <Input
                        id={`start-${index}`}
                        type="time"
                        value={slot.startTime}
                        onChange={(e) => handleTimeSlotChange(index, "startTime", e.target.value)}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor={`end-${index}`} className="text-xs">End Time</Label>
                      <Input
                        id={`end-${index}`}
                        type="time"
                        value={slot.endTime}
                        onChange={(e) => handleTimeSlotChange(index, "endTime", e.target.value)}
                      />
                    </div>
                  </div>
                </div>
              </div>
            ))}
            
            <Button
              type="button"
              variant="outline"
              onClick={handleAddTimeSlot}
              className="w-full flex gap-2 mt-2"
            >
              <Plus size={18} />
              Add Another Time Option
            </Button>
          </div>
          
          {/* Submit Button */}
          <Button 
            type="submit" 
            className="w-full"
            disabled={isSubmitting}
          >
            Create Event
          </Button>
        </form>
      </main>
    </div>
  );
};

export default CreateEvent;
