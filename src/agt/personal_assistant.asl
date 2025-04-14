// personal assistant agent

broadcast(jason).

/* Initial goals */ 

// The agent has the goal to start
!start.

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: true (the plan is always applicable)
 * Body: greets the user
*/
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

/* 
 * Message-handling plan: When a tell message carrying an upcoming event is received,
 * add the corresponding belief.
 */
@handle_inform_upcoming_event
+message(tell, upcoming_event(NE)) : true <-
    .print("Received upcoming event message: ", upcoming_event(NE));
    +upcoming_event(NE).


/* 
 * When a new upcoming event "now" is added, check the user state.
 * If the owner is awake, simply print "Enjoy your event".
 * If the owner is asleep, start the wake-up routine.
 */
@upcoming_event_plan_awake
+upcoming_event("now") : owner_state(awake) <-
    .print("Enjoy your event").

@upcoming_event_plan_asleep
+upcoming_event("now") : owner_state(asleep) <-
    .print("Starting wake-up routine");
    !broadcast_cfp.

/*
 * Plan to broadcast a Call For Proposals (CFP) for the wake-up task.
 * (In this example, we use Jason’s broadcast mechanism.)
 */
@broadcast_cfp_plan
+!broadcast_cfp : true <-
    .broadcast(cfp, wake_up);
    .print("CFP broadcast for wake-up sent").

/*
 * Plan to handle incoming proposals.
 * Proposals are received as messages of the form:
 *   proposal(Agent, Action)
 * where Action can be "raise_blinds" (from the blinds controller) or
 * "turn_on_lights" (from the lights controller).
 */
@handle_proposals_blinds
+proposal(Agent, raise_blinds) : true <-
    .print("Received proposal from ", Agent, " to raise blinds");
    .send(Agent, accept, raise_blinds);
    .print("Accepted proposal from ", Agent).

@handle_proposals_lights
+proposal(Agent, turn_on_lights) : true <-
    .print("Received proposal from ", Agent, " to turn on lights");
    .send(Agent, accept, turn_on_lights);
    .print("Accepted proposal from ", Agent).

/* 
 * Optionally, add a plan to handle refusal messages or finalize the contract net process.
 * For example, after a delay, reject any remaining proposals.
 */
@finalize_cnp
+!finalize_cnp : true <-
    .broadcast(reject, wake_up);
    .print("Finalizing CNP: remaining proposals rejected").


/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }