
import { useState } from "react";
import { format, parseISO } from "date-fns";
import { Check } from "lucide-react";
import { cn } from "@/lib/utils";

export type TimeSlotData = {
  id: string;
  startTime: string;
  endTime: string;
  date: string;
};

type TimeSlotProps = {
  timeSlot: TimeSlotData;
  isSelected: boolean;
  onToggle: (id: string) => void;
  attendees?: string[];
};

const TimeSlot = ({ timeSlot, isSelected, onToggle, attendees = [] }: TimeSlotProps) => {
  const formatDate = (dateStr: string) => {
    const date = parseISO(dateStr);
    return format(date, "EEE, MMM d");
  };

  const formatTime = (timeStr: string) => {
    const time = parseISO(timeStr);
    return format(time, "h:mm a");
  };

  return (
    <div 
      className={cn(
        "time-slot group animate-fade-in",
        isSelected && "selected"
      )}
      onClick={() => onToggle(timeSlot.id)}
    >
      <div className="flex justify-between items-center">
        <div>
          <div className="font-medium">{formatDate(timeSlot.date)}</div>
          <div className="text-muted-foreground">
            {formatTime(timeSlot.startTime)} - {formatTime(timeSlot.endTime)}
          </div>
        </div>
        
        <div className={cn(
          "w-6 h-6 rounded-full flex items-center justify-center transition-all",
          isSelected ? "bg-primary text-primary-foreground" : "border-2 border-muted-foreground/30 group-hover:border-primary/70"
        )}>
          {isSelected && <Check size={14} />}
        </div>
      </div>
      
      {attendees.length > 0 && (
        <div className="mt-2 flex gap-1 flex-wrap">
          {attendees.map((name, idx) => (
            <span 
              key={idx} 
              className="inline-flex text-xs py-0.5 px-2 rounded-full bg-primary/15 text-primary-foreground"
            >
              {name}
            </span>
          ))}
        </div>
      )}
    </div>
  );
};

export default TimeSlot;
