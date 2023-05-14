#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo -e "\n~~~ NUMBER GUESSING GAME ~~~\n"

# get username
echo "Enter your username:"
read INPUT_USERNAME

# check if input_username has > 22 characters
while [[ ! $INPUT_USERNAME =~ ^.{,22}$ ]];
do
  # echo -e "\nPlease enter a valid input (<= 22 characters).\n"
  echo "Enter your username:"
  read INPUT_USERNAME
done

# query by username
QUERY_RESULT=$($PSQL "SELECT user_id, username, COUNT(game_id) AS games_played, COALESCE(MIN(number_of_guesses), 0) AS best_game FROM users LEFT JOIN games USING(user_id) WHERE username='$INPUT_USERNAME' GROUP BY user_id, username;")
# if username does not exist
if [[ -z $QUERY_RESULT ]]; then
  # insert new username to db
  INSERT_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$INPUT_USERNAME');")

  # get user_id
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$INPUT_USERNAME';")

  # print message
  echo "Welcome, $INPUT_USERNAME! It looks like this is your first time here."

# if username already exist
else
  # print message
  echo "$QUERY_RESULT" | while IFS='|' read USER_ID USERNAME GAMES_PLAYED BEST_GAME
  do 
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# START GAME
# generate secret number (1-1000)
SECRET_NUMBER=$((RANDOM % 1001))
echo "Guess the secret number between 1 and 1000:"
read INPUT_GUESS

# add NUMBER_OF_GUESSES as iterator
NUMBER_OF_GUESSES=1

# while loop
while [[ "$INPUT_GUESS" != "$SECRET_NUMBER" ]];
do
  # check if INPUT_GUESS is integer
  if [[ ! $INPUT_GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    read INPUT_GUESS
    (( NUMBER_OF_GUESSES++ ))

  # check if INPUT_GUESS is greater than SECRET_NUMBER
  elif [[ $INPUT_GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
    read INPUT_GUESS
    (( NUMBER_OF_GUESSES++ ))

  # check if INPUT_GUESS is less than SECRET_NUMBER
  elif [[ $INPUT_GUESS -lt $SECRET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
    read INPUT_GUESS
    (( NUMBER_OF_GUESSES++ ))
  fi
done

# insert to games table
# get user_id again
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$INPUT_USERNAME';")
INSERT_RESULT=$($PSQL "INSERT INTO games(user_id, secret_number, number_of_guesses, solved) VALUES($USER_ID, $SECRET_NUMBER, $NUMBER_OF_GUESSES, TRUE);")

# print final message
echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
exit 0
