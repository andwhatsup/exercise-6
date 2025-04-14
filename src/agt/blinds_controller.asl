// blinds controller agent

/* Initial beliefs */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Blinds (was:Blinds)
td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Blinds", "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/blinds.ttl").

// the agent initially believes that the blinds are "lowered"
blinds("lowered").

/* Initial goals */ 

// The agent has the goal to start
!start.

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agents believes that a WoT TD of a was:Blinds is located at Url
 * Body: greets the user
*/
@init_mqtt_plan
+!start : true <-
    makeArtifact("mqtt_blinds", "room.MQTTArtifact", ["blinds_controller"], MQTTArt);
    focus(MQTTArt);
    .print("MQTT artifact created and focused").

@start_plan
+!start : td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Blinds", Url) <-
    .print("Blinds controller starting");
    makeArtifact("blinds", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Url], BlindsArt);
    .print("Blinds artifact created").

/* 
 * Plan to react to a CFP for waking up.
 * If a CFP "wake_up" is received and the blinds are lowered, send a proposal.
 */
@cfp_react_blinds_raise
+cfp(wake_up) : blinds(lowered) <-
    .send("personal_assistant", proposal, raise_blinds);
    .print("Blinds controller proposes to raise blinds").

@cfp_react_blinds_refuse
+cfp(wake_up) : not blinds(lowered) <-
    .send("personal_assistant", refuse, raise_blinds);
    .print("Blinds controller refuses to raise blinds").

/*
 * When an acceptance is received for raising blinds, execute the goal.
 */
@accept_blinds
+accept(raise_blinds) : true <-
    !raise_blinds.

// Plan to raise the blinds
@raise_blinds_plan
+!raise_blinds : true <-
    .print("Raising blinds...");
    // Invoke the action affordance was:SetState with the parameter "raised"
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState", "raised");
    // Optionally update the belief
    -+blinds("lowered");
    +blinds("raised");
    .print("Blinds have been raised");
    // Inform the personal assistant.
    .send("personal_assistant", tell, blinds_state(raised)).

// Plan to lower the blinds
@lower_blinds_plan
+!lower_blinds : true <-
    .print("Lowering blinds...");
    // Invoke the action affordance was:SetState with the parameter "lowered"
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState", "lowered");
    // Optionally update the belief
    -+blinds("raised");
    +blinds("lowered");
    .print("Blinds have been lowered");
    // Inform the personal assistant.
    .send("personal_assistant", tell, blinds_state(lowered)).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }