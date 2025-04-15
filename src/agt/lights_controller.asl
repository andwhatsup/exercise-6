// lights controller agent

/* Initial beliefs */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights (was:Lights)
td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights", "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/lights.ttl").

// The agent initially believes that the lights are "off"
lights("off").

/* Initial goals */ 

// The agent has the goal to start
!start.

/* --- Initialization --- */
// Initialize the MQTT artifact for the lights controller.
@init_mqtt_plan
+!start : true <-
    makeArtifact("mqtt_lights", "room.MQTTArtifact", ["lights_controller"], MQTTArt);
    focus(MQTTArt);
    .print("MQTT artifact created and focused").

@start_plan
+!start : td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights", Url) <-
    .print("Lights controller starting");
    makeArtifact("lights", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Url], LightsArt);
    .print("Lights artifact created").

/* --- CFP Reaction (Existing Plans) --- */
// When a CFP "wake_up" is received and the lights are off, propose to turn them on.
@cfp_react_lights_off
+cfp(wake_up) : lights(off) <-
    .print("Lights: Received CFP; lights are off");
    .send("personal_assistant", proposal, turn_on_lights);
    .print("Lights: Proposal to turn on lights sent").

// If the lights are not off, refuse the CFP.
@cfp_react_lights_on
+cfp(wake_up) : not lights(off) <-
    .print("Lights: Received CFP; lights are not off");
    .send("personal_assistant", refuse, turn_on_lights);
    .print("Lights: Refusal sent").

/* --- Handling Acceptance --- */
// When an acceptance for turning on lights is received, execute the goal.
@accept_lights
+accept(turn_on_lights) : true <-
    .print("Lights: Received acceptance for turning on lights");
    !turn_on_lights.

/* --- Executing Action --- */
// Plan to turn the lights on.
@turn_on_lights_plan
+!turn_on_lights : true <-
    .print("Lights: Turning lights on...");
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState", "on");
    -+lights("off");
    +lights("on");
    .print("Lights: Lights have been turned on");
    .send("personal_assistant", tell, lights_state(on)).

/* --- Optional: Turning Lights Off --- */
@turn_off_lights_plan
+!turn_off_lights : true <-
    .print("Lights: Turning lights off...");
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState", "off");
    -+lights("on");
    +lights("off");
    .print("Lights: Lights have been turned off");
    .send("personal_assistant", tell, lights_state(off)).

/* --- Handling Incoming CFP via KQML --- */
// This plan handles incoming CFP messages (from the personal assistant)
@cfp_received_plan
+!kqml_received(Sender, cfp, wake_up, MessageId) : true <-
    if (lights(off)) {
         .print("Lights: Received CFP from ", Sender, "; lights are off");
         .send("personal_assistant", proposal, turn_on_lights);
         .print("Lights: Proposal to turn on lights sent");
    } else {
         .print("Lights: Received CFP from ", Sender, "; lights are not off");
         .send("personal_assistant", refuse, turn_on_lights);
         .print("Lights: Refusal sent");
    }.

{ include("$jacamoJar/templates/common-cartago.asl") }
