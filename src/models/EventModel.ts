
import { nanoid } from "nanoid";

export interface TimeOption {
  id: string;
  date: string;
  startTime: string;
  endTime: string;
}

export interface Attendee {
  id: string;
  name: string;
  selectedTimeIds: string[];
  comment?: string;
}

export interface Event {
  id: string;
  title: string;
  description?: string;
  location?: string;
  createdBy: string;
  createdAt: string;
  timeOptions: TimeOption[];
  attendees: Attendee[];
}

export const createNewEvent = (
  title: string,
  description: string,
  location: string,
  createdBy: string,
  timeOptions: Omit<TimeOption, "id">[]
): Event => {
  return {
    id: nanoid(),
    title,
    description,
    location,
    createdBy,
    createdAt: new Date().toISOString(),
    timeOptions: timeOptions.map(option => ({
      ...option,
      id: nanoid()
    })),
    attendees: []
  };
};

export const addAttendeeToEvent = (
  event: Event,
  name: string,
  selectedTimeIds: string[],
  comment?: string
): Event => {
  const newAttendee: Attendee = {
    id: nanoid(),
    name,
    selectedTimeIds,
    comment
  };

  return {
    ...event,
    attendees: [...event.attendees, newAttendee]
  };
};

export const findBestTimeOptions = (event: Event): TimeOption[] => {
  if (!event.attendees.length || !event.timeOptions.length) {
    return [];
  }
  
  // Count votes for each time option
  const votes = event.timeOptions.map(option => {
    const count = event.attendees.filter(
      attendee => attendee.selectedTimeIds.includes(option.id)
    ).length;
    
    return { option, count };
  });
  
  // Sort by vote count (descending)
  votes.sort((a, b) => b.count - a.count);
  
  // Get the highest vote count
  const highestCount = votes[0].count;
  
  // Return all options with the highest count
  return votes
    .filter(vote => vote.count === highestCount && vote.count > 0)
    .map(vote => vote.option);
};
