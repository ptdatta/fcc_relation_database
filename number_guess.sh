#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=users -t --no-align -c"
SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))

ASK_USERNAME(){
  echo -e "\nEnter your username:"
  read USERNAME

  USERNAME_CHARACTERS=$(echo $USERNAME | wc -c)
  if [[ $USERNAME_CHARACTERS -gt 22 ]]; then
    ASK_USERNAME
  fi
}

ASK_USERNAME
RETURNING_USER=$($PSQL "SELECT name FROM users WHERE name = '$USERNAME'")

if [[ -z $RETURNING_USER ]]; then
  INSERTED_USER=$($PSQL "INSERT INTO users (name,games_played) VALUES ('$USERNAME',0)")
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
else
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE name = '$USERNAME'")
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE name = '$USERNAME'")
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Grab user_id
USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USERNAME'")

TRIES=1
GUESS=0

GUESSING_MACHINE(){
  read GUESS

  while [[ $GUESS =~ ^[+-]?[0-9]+$ && ! $GUESS -eq $SECRET_NUMBER ]]; do
    TRIES=$(expr $TRIES + 1)

    if [[ $GUESS -gt $SECRET_NUMBER ]]; then
      echo -e "\nIt's lower than that, guess again:"
    else
      echo -e "\nIt's higher than that, guess again:"
    fi

    read GUESS
  done

  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo -e "\nThat is not an integer, guess again:"
    TRIES=$(expr $TRIES + 1)
    GUESSING_MACHINE
  fi
}

echo -e "\nGuess the secret number between 1 and 1000:"
GUESSING_MACHINE

RETURNING_TRIES=$($PSQL "SELECT best_game FROM users WHERE name = '$USERNAME'")
RETURNING_GAMES=$($PSQL "SELECT games_played FROM users WHERE name = '$USERNAME'")

if [[ -z $RETURNING_TRIES ]]; then
  # User is new, insert data for the first game
  UPDATED_USER=$($PSQL "UPDATE users SET best_game = $TRIES, games_played = games_played + 1 WHERE user_id = $USER_ID")
else
  # User has played before, compare the results
  if [[ $TRIES -lt $RETURNING_TRIES ]]; then
    # Update best_game and increment games_played
    UPDATED_USER=$($PSQL "UPDATE users SET best_game = $TRIES, games_played = games_played + 1 WHERE user_id = $USER_ID")
  else
    # Just increment games_played
    UPDATED_USER=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_id = $USER_ID")
  fi
fi

PLURAL_TRIES=$(if [[ $TRIES -eq 1 ]]; then echo "try"; else echo "tries"; fi)
echo -e "\nYou guessed it in $TRIES $PLURAL_TRIES. The secret number was $SECRET_NUMBER. Nice job!"


https://github.com/ptdatta/fcc_relation_database.git