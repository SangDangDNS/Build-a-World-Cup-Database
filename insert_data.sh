#! /bin/bash

# Set PGPASSFILE environment variable to point to the .pgpass file
export PGPASSFILE=/home/sang/.pgpass

PSQL="psql -h localhost -p 5432 -U root -d worldcup --no-align --tuples-only -c"
echo $($PSQL "TRUNCATE teams, games")

cat games.csv | while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  if [[ $WINNER != "winner" ]]
  then
    # get team winner
    TEAM_WINNER=$($PSQL "SELECT name FROM teams WHERE name='$WINNER'")

    # if not found
    if [[ -z $TEAM_WINNER ]]
    then
      # insert name
      INSERT_TEAM_WINNER=$($PSQL "INSERT INTO teams(name) VALUES('$WINNER')")
      if [[ $INSERT_TEAM_WINNER == "INSERT 0 1" ]]
      then
        echo Inserted into teams, $WINNER
      fi   
    fi
  fi

  if [[ $OPPONENT != "opponent" ]]
  then
    # get team opponent
    TEAM_OPPONENT=$($PSQL "SELECT name FROM teams WHERE name='$OPPONENT'")

    # if not found
    if [[ -z $TEAM_OPPONENT ]]
    then
      # insert name
      INSERT_TEAM_OPPONENT=$($PSQL "INSERT INTO teams(name) VALUES('$OPPONENT')")
      if [[ $INSERT_TEAM_OPPONENT == "INSERT 0 1" ]]
      then
        echo Inserted into teams, $OPPONENT
      fi   
    fi
  fi

  if [[ $YEAR != "year" ]]
  then
    #GET WINNER_ID
    WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
    #GET OPPONENT_ID
    OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")
    #INSERT NEW GAMES ROW
    INSERT_GAME=$($PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES ($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS)")
      # echo call to let us know what was added
      if [[ $INSERT_GAME == "INSERT 0 1" ]]
        then
          echo New game added: $YEAR, $ROUND, $WINNER_ID VS $OPPONENT_ID, score $WINNER_GOALS : $OPPONENT_GOALS
      fi
  fi

done