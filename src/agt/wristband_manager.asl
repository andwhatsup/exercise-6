// wristband manager agent

/* Initial beliefs */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Wristband (was:Wristband)
td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Wristband", "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/wristband-simu.ttl").

// The agent has an empty belief about the state of the wristband's owner
owner_state(_).

/* Initial goals */ 

// The agent has the goal to start
!start. 

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agents believes that a WoT TD of a was:Wristband is located at Url
 * Body: the agent creates a ThingArtifact using the WoT TD of a was:Wristband and creates the goal to read the owner's state
*/
@start_plan
+!start : td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Wristband", Url) <-
    .print("Hello world");
    // performs an action that creates a new artifact of type ThingArtifact, named "wristband" using the WoT TD located at Url
    // the action unifies ArtId with the ID of the artifact in the workspace
    makeArtifact("wristband", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Url], ArtId);
    !read_owner_state. // creates the goal !read_owner_state

/* 
 * Plan for reacting to the addition of the goal !read_owner_state
 * Triggering event: addition of goal !read_owner_state
 * Context: true (the plan is always applicable)
 * Body: every 5000ms, the agent exploits the TD Property Affordance of type was:ReadOwnerState to perceive the owner's state
 *       and updates its belief owner_state accordingly
*/
@read_owner_state_plan
+!read_owner_state : true <-
    // Read the owner's state property from the ThingArtifact.
    readProperty("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#ReadOwnerState", OwnerStateLst);
    // Extract the first element from the list, e.g., "asleep".
    .nth(0, OwnerStateLst, State);
    // Remove any previous owner_state belief (regardless of value)
    -owner_state(_);
    // Add the new owner_state belief.
    +owner_state(State);
    .print("The owner is ", State);
    // Inform the personal assistant about the owner state change.
    .send("personal_assistant", tell, State);
    .wait(5000);
    !read_owner_state.

/* 
 * Plan for reacting to the addition of the belief !owner_state
 * Triggering event: addition of belief !owner_state
 * Context: true (the plan is always applicable)
 * Body: announces the current state of the owner
*/
@owner_state_plan
+owner_state(State) : true <-
    .print("The owner is ", State).

@ignore_cfp
+!kqml_received(Sender, cfp, wake_up, MessageId) : true <-
    .print("Wristband Manager ignoring CFP from ", Sender).
    
/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }