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

/* --- Initialization --- */
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

/* --- CFP Reaction --- */
// When a CFP "wake_up" is received and the blinds are lowered, propose to raise the blinds.
@cfp_received_blinds
+!kqml_received(Sender, cfp, wake_up, MessageId) : blinds("lowered") <-
    .print("Blinds: Received CFP from ", Sender, "; blinds are lowered");
    .send("personal_assistant", proposal, raise_blinds);
    .print("Blinds: Proposal to raise blinds sent").

// If the blinds are not lowered, refuse the CFP.
@cfp_react_blinds_not_lowered
+!kqml_received(Sender, cfp, wake_up, MessageId) : not blinds("lowered") <-
    .print("Blinds: Received CFP; blinds are not lowered");
    .send("personal_assistant", refuse, raise_blinds);
    .print("Blinds: Refusal sent").

/* --- Handling Acceptance --- */
// When an acceptance for raising blinds is received, execute the goal.
@accept_blinds
+accept(raise_blinds) : true <-
    .print("Blinds: Received acceptance for raising blinds");
    !raise_blinds.

/* --- Executing Action --- */
// Plan to raise the blinds.
@raise_blinds_plan
+!raise_blinds : true <-
    .print("Blinds: Raising blinds...");
    invokeAction("was:SetState", ["raised"]);
    -+blinds("lowered");
    +blinds("raised");
    .print("Blinds: Blinds have been raised");
    .send("personal_assistant", tell, blinds_state(raised)).

/* --- Optional: Lowering Blinds --- */
@lower_blinds_plan
+!lower_blinds : true <-
    .print("Blinds: Lowering blinds...");
    invokeAction("was:SetState", ["lowered"]);
    -+blinds("raised");
    +blinds("lowered");
    .print("Blinds: Blinds have been lowered");
    .send("personal_assistant", tell, blinds_state(lowered)).

/* --- CFP Received Handling via KQML --- */
// Handle incoming CFP messages (with performative cfp and content wake_up) sent by the personal assistant.
@cfp_received_plan
+!kqml_received(Sender, cfp, wake_up, MessageId) : true <-
    if (blinds(lowered)) {
         .print("Blinds: Received CFP from ", Sender, "; blinds are lowered");
         .send("personal_assistant", proposal, raise_blinds);
         .print("Blinds: Proposal to raise blinds sent");
    } else {
         .print("Blinds: Received CFP from ", Sender, "; blinds are not lowered");
         .send("personal_assistant", refuse, raise_blinds);
         .print("Blinds: Refusal sent");
    }.

{ include("$jacamoJar/templates/common-cartago.asl") }
