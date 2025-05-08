import java.util.HashSet;
class Radio {
  HashSet<PVector> enemyPositions = new HashSet<>(); // Stores reported enemy positions

  void reportEnemy(PVector enemyPos) {
    enemyPositions.add(enemyPos);
  }

  //TODO remake so the tanks angle towards enemy and make sure that there is no obstacle between
  //them according to memory and fire.

  //void commandAllies(Tank playerTank, ArrayList<Tank> allies) {
  //  for (Tank ally : allies) {
  //    if (!enemyPositions.isEmpty()) {
  //      ally.navigateTo(enemyPositions.get(0)); // Move towards first known enemy
  //    } else {
  //      ally.moveToward(playerTank.position); // Gather near player
  //    }
  //  }
  //}
}
