class QLearner {
  HashMap<Tank.State, HashMap<String, Float>> qTable;
  float learningRate;
  float discountFactor;
  float epsilon; // for epsilon-greedy exploration
 
  String[] actions = {"move", "rotateLeft", "rotateRight", "stop", "fire"};

  QLearner(float alpha, float gamma, float eps) {
    learningRate = alpha;
    discountFactor = gamma;
    epsilon = eps;
    qTable = new HashMap<Tank.State, HashMap<String, Float>>(); // Hashmap from each State -> Action + Q value
  }
 
  // Ensure the Q-table has an entry for the given state
  void ensureState(Tank.State state) {
    if (!qTable.containsKey(state)) {
      HashMap<String, Float> actionValues = new HashMap<String, Float>();
      for (String action : actions) {
        actionValues.put(action, 0.0f);
      }
      qTable.put(state, actionValues);
    }
  }
 
  // Choose an action based on the current state using epsilon-greedy policy
  String chooseAction(Tank.State state) {
    ensureState(state);
    if (random(1) < epsilon) {
      // Exploration: randomly choose any valid action.
      int idx = int(random(actions.length));
      return actions[idx];
    } else {
      // Exploitation: choose the action with the highest Q-value.
      float bestValue = -Float.MAX_VALUE;
      String bestAction = actions[0];
      for (String action : actions) {
        float value = qTable.get(state).get(action);
        if (value > bestValue) {
          bestValue = value;
          bestAction = action;
        }
      }
      return bestAction;
    }
  }
 
  // Update the Q-table based on the state, action taken, reward received, and the next state.
  void updateQ(Tank.State state, String action, int reward, Tank.State nextState) {
    ensureState(state);
    ensureState(nextState);
    float currentQ = qTable.get(state).get(action);
    // Find the max Q-value for the next state.
    float maxNextQ = -Float.MAX_VALUE;
    for (String a : actions) {
      float qVal = qTable.get(nextState).get(a);
      if (qVal > maxNextQ) {
        maxNextQ = qVal;
      }
    }
    // Q-learning update formula.
    float newQ = currentQ + learningRate * (reward + discountFactor * maxNextQ - currentQ);
    qTable.get(state).put(action, newQ);
  }
}
