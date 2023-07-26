# Build-a-World-Cup-Database

You start with several files, one of them is `games.csv`. It contains a comma-separated list of all games of the final three rounds of the World Cup tournament since 2014; the titles are at the top. It includes the year of each game, the round of the game, the winner, their opponent, and the number of goals each team scored. You need to following the below instruction for this project:  

## Step 1: Create Docker-compose file

You will use docker compose to create a container docker for Postgres.  

Pls create a file `docker-compose.yaml` and a folder `worldcup_data`.    

File `docker-compose.yaml`    
```
services:
  pgdatabase:
    image: postgres:13
    environment:
      - POSTGRES_USER=root
      - POSTGRES_PASSWORD=root
      - POSTGRES_DB=worldcup
    volumes:
      - "./worldcup_data:/var/lib/postgresql/data:rw"
    ports:
      - "5432:5432"
```

To start a postgres instance, run this command:  
`sudo docker-compose up -d`

**Note:** If you want to stop that docker compose, pls enter this command: `sudo docker-compose down`  

Ensure that the .pgpass file is properly set up to avoid any password prompts. If the .pgpass file doesn't exist, create it in your home directory and set the appropriate permissions:

```
touch ~/.pgpass
chmod 600 ~/.pgpass
```

Open the .pgpass file in a text editor and add the following line with the appropriate values for your PostgreSQL server:

```
localhost:5432:worldcup:root:your_password_here
``` 

To log in to PostgreSQL with psql to create your database. Do that by entering this command in your terminal:

```
psql -h <hostname> -p <port> -U <username> -d <database>
```

## Step 2: Create table in DB

Create 2 tables `teams` and `games` for DB like the below:  

```
CREATE TABLE teams (
  team_id SERIAL PRIMARY KEY,
  name VARCHAR(20) NOT NULL UNIQUE
);
```

```
CREATE TABLE games (
  game_id SERIAL PRIMARY KEY,
  year INTEGER NOT NULL,
  round VARCHAR(30) NOT NULL,
  winner_id INTEGER NOT NULL,
  opponent_id INTEGER NOT NULL,
  winner_goals INTEGER NOT NULL,
  opponent_goals INTEGER NOT NULL,
  FOREIGN KEY (winner_id) REFERENCES teams (team_id),
  FOREIGN KEY (opponent_id) REFERENCES teams (team_id)
);
```

```
worldcup=> \d teams;
                                      Table "public.teams"
 Column  |         Type          | Collation | Nullable |                Default                 
---------+-----------------------+-----------+----------+----------------------------------------
 team_id | integer               |           | not null | nextval('teams_team_id_seq'::regclass)
 name    | character varying(20) |           | not null | 
Indexes:
    "teams_pkey" PRIMARY KEY, btree (team_id)
    "teams_name_key" UNIQUE CONSTRAINT, btree (name)
Referenced by:
    TABLE "games" CONSTRAINT "games_opponent_id_fkey" FOREIGN KEY (opponent_id) REFERENCES teams(team_id)
    TABLE "games" CONSTRAINT "games_winner_id_fkey" FOREIGN KEY (winner_id) REFERENCES teams(team_id)
```

```
worldcup=> \d games
                                          Table "public.games"
     Column     |         Type          | Collation | Nullable |                Default                 
----------------+-----------------------+-----------+----------+----------------------------------------
 game_id        | integer               |           | not null | nextval('games_game_id_seq'::regclass)
 year           | integer               |           | not null | 
 round          | character varying(30) |           | not null | 
 winner_id      | integer               |           | not null | 
 opponent_id    | integer               |           | not null | 
 winner_goals   | integer               |           | not null | 
 opponent_goals | integer               |           | not null | 
Indexes:
    "games_pkey" PRIMARY KEY, btree (game_id)
Foreign-key constraints:
    "games_opponent_id_fkey" FOREIGN KEY (opponent_id) REFERENCES teams(team_id)
    "games_winner_id_fkey" FOREIGN KEY (winner_id) REFERENCES teams(team_id)
```
## Step 3: Create Bash file to insert data

And then, you will create the Bash script file `insert_data.sh`. Ensure the script has execution permission: 

```
chmod +x insert_data.sh
```

File `insert_data.sh`  

```
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
```

Execute that Bash file: `./insert_data.sh`  

The result:

```
TRUNCATE TABLE
Inserted into teams, France
Inserted into teams, Croatia
New game added: 2018, Final, 1 VS 2, score 4 : 2
Inserted into teams, Belgium
Inserted into teams, England
New game added: 2018, Third Place, 3 VS 4, score 2 : 0
New game added: 2018, Semi-Final, 2 VS 4, score 2 : 1
New game added: 2018, Semi-Final, 1 VS 3, score 1 : 0
Inserted into teams, Russia
New game added: 2018, Quarter-Final, 2 VS 5, score 3 : 2
Inserted into teams, Sweden
New game added: 2018, Quarter-Final, 4 VS 6, score 2 : 0
Inserted into teams, Brazil
New game added: 2018, Quarter-Final, 3 VS 7, score 2 : 1
Inserted into teams, Uruguay
New game added: 2018, Quarter-Final, 1 VS 8, score 2 : 0
Inserted into teams, Colombia
New game added: 2018, Eighth-Final, 4 VS 9, score 2 : 1
Inserted into teams, Switzerland
New game added: 2018, Eighth-Final, 6 VS 10, score 1 : 0
Inserted into teams, Japan
New game added: 2018, Eighth-Final, 3 VS 11, score 3 : 2
Inserted into teams, Mexico
New game added: 2018, Eighth-Final, 7 VS 12, score 2 : 0
Inserted into teams, Denmark
New game added: 2018, Eighth-Final, 2 VS 13, score 2 : 1
Inserted into teams, Spain
New game added: 2018, Eighth-Final, 5 VS 14, score 2 : 1
Inserted into teams, Portugal
New game added: 2018, Eighth-Final, 8 VS 15, score 2 : 1
Inserted into teams, Argentina
New game added: 2018, Eighth-Final, 1 VS 16, score 4 : 3
Inserted into teams, Germany
New game added: 2014, Final, 17 VS 16, score 1 : 0
Inserted into teams, Netherlands
New game added: 2014, Third Place, 18 VS 7, score 3 : 0
New game added: 2014, Semi-Final, 16 VS 18, score 1 : 0
New game added: 2014, Semi-Final, 17 VS 7, score 7 : 1
Inserted into teams, Costa Rica
New game added: 2014, Quarter-Final, 18 VS 19, score 1 : 0
New game added: 2014, Quarter-Final, 16 VS 3, score 1 : 0
New game added: 2014, Quarter-Final, 7 VS 9, score 2 : 1
New game added: 2014, Quarter-Final, 17 VS 1, score 1 : 0
Inserted into teams, Chile
New game added: 2014, Eighth-Final, 7 VS 20, score 2 : 1
New game added: 2014, Eighth-Final, 9 VS 8, score 2 : 0
Inserted into teams, Nigeria
New game added: 2014, Eighth-Final, 1 VS 21, score 2 : 0
Inserted into teams, Algeria
New game added: 2014, Eighth-Final, 17 VS 22, score 2 : 1
New game added: 2014, Eighth-Final, 18 VS 12, score 2 : 1
Inserted into teams, Greece
New game added: 2014, Eighth-Final, 19 VS 23, score 2 : 1
New game added: 2014, Eighth-Final, 16 VS 10, score 1 : 0
Inserted into teams, United States
New game added: 2014, Eighth-Final, 3 VS 24, score 2 : 1
```

Check table in the DB:

```
worldcup=# select * from teams;
 team_id |     name      
---------+---------------
       1 | France
       2 | Croatia
       3 | Belgium
       4 | England
       5 | Russia
       6 | Sweden
       7 | Brazil
       8 | Uruguay
       9 | Colombia
      10 | Switzerland
      11 | Japan
      12 | Mexico
      13 | Denmark
      14 | Spain
      15 | Portugal
      16 | Argentina
      17 | Germany
      18 | Netherlands
      19 | Costa Rica
      20 | Chile
      21 | Nigeria
      22 | Algeria
      23 | Greece
      24 | United States
(24 rows)

worldcup=# select * from games;
 game_id | year |     round     | winner_id | opponent_id | winner_goals | opponent_goals 
---------+------+---------------+-----------+-------------+--------------+----------------
       1 | 2018 | Final         |         1 |           2 |            4 |              2
       2 | 2018 | Third Place   |         3 |           4 |            2 |              0
       3 | 2018 | Semi-Final    |         2 |           4 |            2 |              1
       4 | 2018 | Semi-Final    |         1 |           3 |            1 |              0
       5 | 2018 | Quarter-Final |         2 |           5 |            3 |              2
       6 | 2018 | Quarter-Final |         4 |           6 |            2 |              0
       7 | 2018 | Quarter-Final |         3 |           7 |            2 |              1
       8 | 2018 | Quarter-Final |         1 |           8 |            2 |              0
       9 | 2018 | Eighth-Final  |         4 |           9 |            2 |              1
      10 | 2018 | Eighth-Final  |         6 |          10 |            1 |              0
      11 | 2018 | Eighth-Final  |         3 |          11 |            3 |              2
      12 | 2018 | Eighth-Final  |         7 |          12 |            2 |              0
      13 | 2018 | Eighth-Final  |         2 |          13 |            2 |              1
      14 | 2018 | Eighth-Final  |         5 |          14 |            2 |              1
      15 | 2018 | Eighth-Final  |         8 |          15 |            2 |              1
      16 | 2018 | Eighth-Final  |         1 |          16 |            4 |              3
      17 | 2014 | Final         |        17 |          16 |            1 |              0
      18 | 2014 | Third Place   |        18 |           7 |            3 |              0
      19 | 2014 | Semi-Final    |        16 |          18 |            1 |              0
      20 | 2014 | Semi-Final    |        17 |           7 |            7 |              1
      21 | 2014 | Quarter-Final |        18 |          19 |            1 |              0
      22 | 2014 | Quarter-Final |        16 |           3 |            1 |              0
      23 | 2014 | Quarter-Final |         7 |           9 |            2 |              1
      24 | 2014 | Quarter-Final |        17 |           1 |            1 |              0
      25 | 2014 | Eighth-Final  |         7 |          20 |            2 |              1
      26 | 2014 | Eighth-Final  |         9 |           8 |            2 |              0
      27 | 2014 | Eighth-Final  |         1 |          21 |            2 |              0
      28 | 2014 | Eighth-Final  |        17 |          22 |            2 |              1
      29 | 2014 | Eighth-Final  |        18 |          12 |            2 |              1
      30 | 2014 | Eighth-Final  |        19 |          23 |            2 |              1
      31 | 2014 | Eighth-Final  |        16 |          10 |            1 |              0
      32 | 2014 | Eighth-Final  |         3 |          24 |            2 |              1
(32 rows)

```

## Step 4: Dump DB into \<file>.sql

When completed, pls enter in the terminal to dump the database into a students.sql file. It will save all the commands needed to rebuild it. Take a quick look at the file when you are done. The file will be located where the command was entered.  

```
pg_dump --clean --create --inserts --username=root -h localhost worldcup > worldcup.sql
```  

## Step 5: Create Bash file to query data

And then, you will create the Bash script file `queries.sh`. Ensure the script has execution permission: 

```
chmod +x queries.sh
```

File `queries.sh`  

```
#! /bin/bash

# Set PGPASSFILE environment variable to point to the .pgpass file
export PGPASSFILE=/home/sang/.pgpass

PSQL="psql -h localhost -p 5432 -U root -d worldcup --no-align --tuples-only -c"
# Investigating the data 
# to run script: ./insert_data.sh

echo -e "\nTotal number of goals in all games from winning teams:"
echo "$($PSQL "SELECT SUM(winner_goals) FROM games")"

echo -e "\nTotal number of goals in all games from both teams combined:"
echo "$($PSQL "SELECT SUM(winner_goals + opponent_goals) FROM games")"

echo -e "\nAverage number of goals in all games from the winning teams:"
echo "$($PSQL "SELECT AVG(winner_goals) FROM games")"

echo -e "\nAverage number of goals in all games from the winning teams rounded to two decimal places:"
echo "$($PSQL "SELECT ROUND(AVG(winner_goals),2) FROM games ")"

echo -e "\nAverage number of goals in all games from both teams:"
echo "$($PSQL "SELECT AVG(winner_goals + opponent_goals) FROM games")"

echo -e "\nMost goals scored in a single game by one team:"
echo "$($PSQL "SELECT MAX(winner_goals) FROM games")"

echo -e "\nNumber of games where the winning team scored more than two goals:"
echo "$($PSQL "SELECT COUNT(*) FROM games WHERE winner_goals > 2")"

echo -e "\nWinner of the 2018 tournament team name:"
echo "$($PSQL "SELECT name FROM games INNER JOIN teams ON games.winner_id = teams.team_id WHERE year=2018 ORDER BY winner_goals DESC LIMIT 1")"

echo -e "\nList of teams who played in the 2014 'Eighth-Final' round:"
echo "$($PSQL "SELECT name FROM teams LEFT JOIN games ON teams.team_id = games.winner_id OR teams.team_id = games.opponent_id WHERE year = 2014 AND round = 'Eighth-Final' ORDER BY name")"

echo -e "\nList of unique winning team names in the whole data set:"
echo "$($PSQL "SELECT DISTINCT(name) FROM teams INNER JOIN games ON teams.team_id = games.winner_id ORDER BY name")"

echo -e "\nYear and team name of all the champions:"
echo "$($PSQL "SELECT year, name FROM games INNER JOIN teams ON games.winner_id = teams.team_id WHERE round = 'Final' ORDER BY year")"

echo -e "\nList of teams that start with 'Co':"
echo "$($PSQL "SELECT name FROM teams WHERE name LIKE 'Co%'")"
```

Execute that Bash file: `./queries.sh`  

This is the expected output:

```
$ ./queries.sh 

Total number of goals in all games from winning teams:
68

Total number of goals in all games from both teams combined:
90

Average number of goals in all games from the winning teams:
2.1250000000000000

Average number of goals in all games from the winning teams rounded to two decimal places:
2.13

Average number of goals in all games from both teams:
2.8125000000000000

Most goals scored in a single game by one team:
7

Number of games where the winning team scored more than two goals:
6

Winner of the 2018 tournament team name:
France

List of teams who played in the 2014 'Eighth-Final' round:
Algeria
Argentina
Belgium
Brazil
Chile
Colombia
Costa Rica
France
Germany
Greece
Mexico
Netherlands
Nigeria
Switzerland
United States
Uruguay

List of unique winning team names in the whole data set:
Argentina
Belgium
Brazil
Colombia
Costa Rica
Croatia
England
France
Germany
Netherlands
Russia
Sweden
Uruguay

Year and team name of all the champions:
2014|Germany
2018|France

List of teams that start with 'Co':
Colombia
Costa Rica
```
