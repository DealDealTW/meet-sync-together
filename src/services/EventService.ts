
import { Event, createNewEvent, addAttendeeToEvent } from "../models/EventModel";
import { toast } from "sonner";

// In a real app, this would be replaced with API calls
const STORAGE_KEY = "meetSync_events";

export const getEvents = (): Event[] => {
  try {
    const eventsJson = localStorage.getItem(STORAGE_KEY);
    if (!eventsJson) return [];
    return JSON.parse(eventsJson);
  } catch (error) {
    console.error("Error fetching events:", error);
    toast.error("Couldn't load events");
    return [];
  }
};

export const getEventById = (id: string): Event | undefined => {
  try {
    const events = getEvents();
    return events.find(event => event.id === id);
  } catch (error) {
    console.error(`Error fetching event ${id}:`, error);
    toast.error("Couldn't load event");
    return undefined;
  }
};

export const saveEvent = (event: Event): boolean => {
  try {
    const events = getEvents();
    const existingIndex = events.findIndex(e => e.id === event.id);
    
    if (existingIndex >= 0) {
      // Update existing event
      events[existingIndex] = event;
    } else {
      // Add new event
      events.push(event);
    }
    
    localStorage.setItem(STORAGE_KEY, JSON.stringify(events));
    return true;
  } catch (error) {
    console.error("Error saving event:", error);
    toast.error("Couldn't save event");
    return false;
  }
};

export const createEvent = (
  title: string,
  description: string,
  location: string,
  createdBy: string,
  timeOptions: { date: string; startTime: string; endTime: string }[]
): Event | undefined => {
  try {
    const newEvent = createNewEvent(title, description, location, createdBy, timeOptions);
    saveEvent(newEvent);
    toast.success("Event created successfully");
    return newEvent;
  } catch (error) {
    console.error("Error creating event:", error);
    toast.error("Couldn't create event");
    return undefined;
  }
};

export const addAttendee = (
  eventId: string,
  name: string,
  selectedTimeIds: string[],
  comment?: string
): Event | undefined => {
  try {
    const event = getEventById(eventId);
    if (!event) return undefined;
    
    const updatedEvent = addAttendeeToEvent(event, name, selectedTimeIds, comment);
    saveEvent(updatedEvent);
    toast.success("Response submitted");
    return updatedEvent;
  } catch (error) {
    console.error("Error adding attendee:", error);
    toast.error("Couldn't submit your response");
    return undefined;
  }
};

export const deleteEvent = (eventId: string): boolean => {
  try {
    const events = getEvents();
    const updatedEvents = events.filter(event => event.id !== eventId);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(updatedEvents));
    toast.success("Event deleted");
    return true;
  } catch (error) {
    console.error("Error deleting event:", error);
    toast.error("Couldn't delete event");
    return false;
  }
};
