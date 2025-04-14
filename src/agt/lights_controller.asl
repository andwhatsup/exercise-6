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

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agents believes that a WoT TD of a was:Lights is located at Url
 * Body: greets the user
*/
// Plan for initializing the MQTT artifact.
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

/* 
 * Plan to react to a CFP for waking up when lights are off.
 * If a CFP "wake_up" is received and the lights are off, send a proposal.
 */
@cfp_react_lights_off
+cfp(wake_up) : lights(off) <-
    .print("Lights controller received CFP; lights are off");
    .send("personal_assistant", proposal, turn_on_lights);
    .print("Lights controller proposes to turn on lights").

/* 
 * Plan to react to a CFP for waking up when lights are not off.
 * If a CFP "wake_up" is received and the lights are not off, send a refusal.
 */
@cfp_react_lights_not_off
+cfp(wake_up) : not lights(off) <-
    .print("Lights controller received CFP; lights are not off");
    .send("personal_assistant", refuse, turn_on_lights);
    .print("Lights controller refuses to turn on lights").

/*
 * Plan to handle an acceptance for turning on lights.
 * When an acceptance message (accept(turn_on_lights)) is received, execute the goal.
 */
@accept_lights
+accept(turn_on_lights) : true <-
    .print("Lights controller received acceptance for turning on lights");
    !turn_on_lights.

/* 
 * Plan to turn the lights on.
 * This plan invokes the action affordance was:SetState with the parameter "on",
 * updates the belief, prints a message, and informs the personal assistant.
 */
@turn_on_lights_plan
+!turn_on_lights : true <-
    .print("Turning lights on...");
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState", "on");
    -+lights("off");
    +lights("on");
    .print("Lights have been turned on");
    .send("personal_assistant", tell, lights_state(on)).

/* 
 * Plan to turn the lights off.
 * This plan invokes the action affordance was:SetState with the parameter "off",
 * updates the belief, prints a message, and informs the personal assistant.
 */
@turn_off_lights_plan
+!turn_off_lights : true <-
    .print("Turning lights off...");
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState", "off");
    -+lights("on");
    +lights("off");
    .print("Lights have been turned off");
    .send("personal_assistant", tell, lights_state(off)).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }