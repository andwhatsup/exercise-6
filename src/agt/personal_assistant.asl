broadcast(jason).

/* Initial goals */ 
!start.

/* --- Initial Beliefs --- */
// The personal assistant holds the user’s wake-up preferences.
// Lower numeric rank indicates a higher preference.
wakeup_preference(natural, 0).
wakeup_preference(artificial, 1).

/* --- Initialization --- */
// Plan for initializing the MQTT artifact.
@init_mqtt_plan
+!start : true <-
    makeArtifact("mqtt_personal", "room.MQTTArtifact", ["personal_assistant"], MQTTArt);
    focus(MQTTArt);
    .print("MQTT artifact created and focused").

@start_plan
+!start : true <-
    .print("Hello world").

/* --- Message Handling --- */
// Handle incoming messages carrying information (e.g., from calendar and wristband managers).
@kqml_received_plan
+!kqml_received(Sender, tell, Content, MessageId) : true <-
    .print("Personal Assistant received message from ", Sender, ": ", Content);
    if (Content == "now") {
        .print("PA: upcoming_event is now");
        -upcoming_event(_);
        +upcoming_event("now")
    } else {
        if (Content == "awake" | Content == "asleep") {
            .print("PA: owner_state is ", Content);
            -owner_state(_);
            +owner_state(Content)
        }
    };
    !check_wake_up.

@check_wake_up_plan
+!check_wake_up : true <-
    if (upcoming_event("now") & owner_state("awake")) {
        .print("PA: Enjoy your event");
    } else { 
        if (upcoming_event("now") & owner_state("asleep")) {
            .print("PA: Starting wake-up routine");
            !broadcast_cfp;
        }
    }.

/* --- Reaction Based on Beliefs --- */
// When upcoming_event("now") is added while owner_state is awake.
@react_upcoming_awake
+upcoming_event("now") : owner_state(awake) <-
    .print("PA: Enjoy your event").
// When upcoming_event("now") is added while owner_state is asleep.
@react_upcoming_asleep
+upcoming_event("now") : owner_state(asleep) <-
    .print("PA: Starting wake-up routine");
    !broadcast_cfp.

/* --- CFP Broadcasting and Proposal Handling --- */
// broadcasting to all
@broadcast_cfp_plan
+!broadcast_cfp : true <-
    .broadcast(cfp, wake_up);
    .print("PA: CFP broadcast for wake-up sent").

// Handle incoming proposals from any controller.
@handle_proposals
+message(From, tell, proposal(Agent, Action)) : true <-
    .print("PA: Received proposal from ", Agent, " for ", Action);
    .send(Agent, tell, accept(Action));
    .print("PA: Accepted proposal from ", Agent).

@handle_proposals_kqml
+!kqml_received(Sender, proposal, Proposal, MessageId) : true <-
    .print("PA: Received proposal from ", Sender, " for ", Proposal);
    .send(Sender, tell, accept(Proposal));
    .print("PA: Accepted proposal from ", Sender).

// Handle incoming refusal messages.
@handle_refusal
+!kqml_received(Sender, refuse, Content, MessageId) : true <-
    .print("PA: Received refusal from ", Sender, " for ", Content).

// Handle any unexpected CFP messages.
@handle_cfp
+!kqml_received(Sender, cfp, wake_up, MessageId) : true <-
    .print("PA: Received CFP from ", Sender, " (ignored)").

// Optionally, finalize the Contract Net Protocol.
@finalize_cnp
+!finalize_cnp : true <-
    .broadcast(reject, wake_up);
    .print("PA: Finalizing CNP: remaining proposals rejected").

/* --- Delegation if No Proposals Received --- */
// If no acceptable proposals are received within a given timeout,
// delegate the wake-up responsibility to a friend.
@delegate_wake_up
+!check_proposals : true <-
    .wait(5000);
    .print("PA: No acceptable proposals received; delegating wake-up to friend");
    .send("friend_agent", tell, wake_up).

{ include("$jacamoJar/templates/common-cartago.asl") }