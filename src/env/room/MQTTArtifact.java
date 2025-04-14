package room;

import cartago.Artifact;
import cartago.INTERNAL_OPERATION;
import cartago.OPERATION;
import org.eclipse.paho.client.mqttv3.*;

/**
 * A CArtAgO artifact that provides an operation for sending messages to agents 
 * with KQML performatives using the dweet.io API
 */
public class MQTTArtifact extends Artifact {

    MqttClient client;
    String broker = "tcp://test.mosquitto.org:1883";
    String clientId;
    String topic = "was-exercise-6/communication-andi";
    int qos = 2;

    public void init(String name){
        //The name is used for the clientId.
        this.clientId = name;
        try {
            client = new MqttClient(broker, clientId);
            MqttConnectOptions connOpts = new MqttConnectOptions();
            connOpts.setCleanSession(true);
            // Set a custom callback to handle incoming messages
            client.setCallback(new CustomMqttCallback(this));
            client.connect(connOpts);
            // Subscribe to the topic where messages will be published.
            client.subscribe(topic, qos);
            // Define an observable property for perceived MQTT messages.
            defineObsProperty("mqtt_message", "");
        } catch (MqttException me) {
            me.printStackTrace();
        }
    }

    @OPERATION
    public void sendMsg(String agent, String performative, String content){
        // Compose message in the format "sender agent,performative,content"
        String messageStr = agent + "," + performative + "," + content;
        try {
            MqttMessage message = new MqttMessage(messageStr.getBytes());
            message.setQos(qos);
            client.publish(topic, message);
        } catch (MqttException me) {
            me.printStackTrace();
        }
    }

    @INTERNAL_OPERATION
    public void addMessage(String agent, String performative, String content){
        // Compose the received message string.
        String receivedMsg = agent + "," + performative + "," + content;
        // Update the observable property so that agents can perceive this change.
        updateObsProperty("mqtt_message", receivedMsg);
        // Optionally output to console for debugging.
        System.out.println("Received MQTT message: " + receivedMsg);
    }

    // Custom callback class to process incoming MQTT messages.
    private class CustomMqttCallback implements MqttCallback {
        private MQTTArtifact artifact;
        public CustomMqttCallback(MQTTArtifact artifact){
            this.artifact = artifact;
        }

        @Override
        public void connectionLost(Throwable cause) {
            System.err.println("MQTT connection lost: " + cause.getMessage());
        }

        @Override
        public void messageArrived(String topic, MqttMessage message) throws Exception {
            String payload = new String(message.getPayload());
            // Expect messages in the form "sender,performative,content"
            String[] parts = payload.split(",", 3);
            if (parts.length == 3) {
                artifact.addMessage(parts[0], parts[1], parts[2]);
            } else {
                // In case the format is not as expected, use default values.
                artifact.addMessage("unknown", "inform", payload);
            }
        }

        @Override
        public void deliveryComplete(IMqttDeliveryToken token) {
            // No action required here for now.
        }
    }
}