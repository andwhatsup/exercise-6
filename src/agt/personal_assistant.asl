// personal assistant agent
broadcast(jason).

/* Initial goals */ 
// The agent has the goal to start
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
    // Create the MQTT artifact. The second argument is the fully qualified class name.
    makeArtifact("mqtt_personal", "room.MQTTArtifact", ["personal_assistant"], MQTTArt);
    // Focus on the MQTT artifact.
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
// If an upcoming event "now" is added while the owner is awake.
@react_upcoming_awake
+upcoming_event("now") : owner_state(awake) <-
    .print("PA: Enjoy your event").

// If an upcoming event "now" is added while the owner is asleep.
@react_upcoming_asleep
+upcoming_event("now") : owner_state(asleep) <-
    .print("PA: Starting wake-up routine");
    !broadcast_cfp.

/* --- CFP Broadcasting and Proposal Handling --- */
// Broadcast a Call For Proposals (CFP) for the wake-up task.
// Here the CFP message has performative cfp and content wake_up.
@broadcast_cfp_plan
+!broadcast_cfp : true <-
    .broadcast(cfp, wake_up);
    .print("PA: CFP broadcast for wake-up sent").

// Handle incoming proposals from any controller.
// In this simple example, the PA always accepts available proposals.
@handle_proposals
+message(From, tell, proposal(Agent, Action)) : true <-
    .print("PA: Received proposal from ", Agent, " for ", Action);
    // In a full implementation, the PA could compare the proposals’ ranked preferences.
    // Here we simply accept each proposal.
    .send(Agent, accept, Action);
    .print("PA: Accepted proposal from ", Agent).

// Optionally, finalize the Contract Net Protocol (reject any remaining proposals after a delay)
@finalize_cnp
+!finalize_cnp : true <-
    .broadcast(reject, wake_up);
    .print("PA: Finalizing CNP: remaining proposals rejected").


/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }