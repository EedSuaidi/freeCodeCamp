#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=periodic_table --tuples-only -c"

MAIN_PROGRAM() {
  if [[ -z $1 ]]
  then
    echo "Please provide an element as an argument."
  else
    PRINT_ELEMENT $1
  fi
}

PRINT_ELEMENT() {
  INPUT=$1
  if [[ ! $INPUT =~ ^[0-9]+$ ]]
  then
    ATOMIC_NUMBER=$(echo $($PSQL "SELECT atomic_number FROM elements WHERE symbol='$INPUT' OR name='$INPUT';") | sed 's/ //g')
  else
    ATOMIC_NUMBER=$(echo $($PSQL "SELECT atomic_number FROM elements WHERE atomic_number=$INPUT;") | sed 's/ //g')
  fi
  
  if [[ -z $ATOMIC_NUMBER ]]
  then
    echo "I could not find that element in the database."
  else
    TYPE_ID=$(echo $($PSQL "SELECT type_id FROM properties WHERE atomic_number=$ATOMIC_NUMBER;") | sed 's/ //g')
    NAME=$(echo $($PSQL "SELECT name FROM elements WHERE atomic_number=$ATOMIC_NUMBER;") | sed 's/ //g')
    SYMBOL=$(echo $($PSQL "SELECT symbol FROM elements WHERE atomic_number=$ATOMIC_NUMBER;") | sed 's/ //g')
    ATOMIC_MASS=$(echo $($PSQL "SELECT atomic_mass FROM properties WHERE atomic_number=$ATOMIC_NUMBER;") | sed 's/ //g')
    MELTING_POINT_CELSIUS=$(echo $($PSQL "SELECT melting_point_celsius FROM properties WHERE atomic_number=$ATOMIC_NUMBER;") | sed 's/ //g')
    BOILING_POINT_CELSIUS=$(echo $($PSQL "SELECT boiling_point_celsius FROM properties WHERE atomic_number=$ATOMIC_NUMBER;") | sed 's/ //g')
    TYPE=$(echo $($PSQL "SELECT type FROM elements LEFT JOIN properties USING(atomic_number) LEFT JOIN types USING(type_id) WHERE atomic_number=$ATOMIC_NUMBER;") | sed 's/ //g')

    echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $TYPE, with a mass of $ATOMIC_MASS amu. $NAME has a melting point of $MELTING_POINT_CELSIUS celsius and a boiling point of $BOILING_POINT_CELSIUS celsius."
  fi
}

FIX_DB() {
  RENAME_PROPERTIES_WEIGHT=$($PSQL "ALTER TABLE properties RENAME COLUMN weight TO atomic_mass;")
  echo "RENAME_PROPERTIES_WEIGHT                    : $RENAME_PROPERTIES_WEIGHT"

  RENAME_PROPERTIES_MELTING_POINT=$($PSQL"ALTER TABLE properties RENAME COLUMN melting_point TO melting_point_celsius;")
  RENAME_PROPERTIES_BOILING_POINT=$($PSQL"ALTER TABLE properties RENAME COLUMN boiling_point TO boiling_point_celsius;")
  echo "RENAME_PROPERTIES_MELTING_POINT             : $RENAME_PROPERTIES_MELTING_POINT"
  echo "RENAME_PROPERTIES_BOILING_POINT             : $RENAME_PROPERTIES_BOILING_POINT"

  ALTER_PROPERTIES_MELTING_POINT_NOT_NULL=$($PSQL"ALTER TABLE properties ALTER COLUMN melting_point_celsius SET NOT NULL;")
  ALTER_PROPERTIES_BOILING_POINT_NOT_NULL=$($PSQL "ALTER TABLE properties ALTER COLUMN boiling_point_celsius SET NOT NULL;")
  echo "ALTER_PROPERTIES_MELTING_POINT_NOT_NULL     : $ALTER_PROPERTIES_MELTING_POINT_NOT_NULL"
  echo "ALTER_PROPERTIES_BOILING_POINT_NOT_NULL     : $ALTER_PROPERTIES_BOILING_POINT_NOT_NULL"

  ALTER_ELEMENTS_SYMBOL_UNIQUE=$($PSQL "ALTER TABLE elements ADD UNIQUE(symbol);")
  ALTER_ELEMENTS_NAME_UNIQUE=$($PSQL "ALTER TABLE elements ADD UNIQUE(name);")
  echo "ALTER_ELEMENTS_SYMBOL_UNIQUE                : $ALTER_ELEMENTS_SYMBOL_UNIQUE"
  echo "ALTER_ELEMENTS_NAME_UNIQUE                  : $ALTER_ELEMENTS_NAME_UNIQUE"

  ALTER_ELEMENTS_SYMBOL_NOT_NULL=$($PSQL "ALTER TABLE elements ALTER COLUMN symbol SET NOT NULL;")
  ALTER_ELEMENTS_SYMBOL_NOT_NULL=$($PSQL "ALTER TABLE elements ALTER COLUMN name SET NOT NULL;")
  echo "ALTER_ELEMENTS_SYMBOL_NOT_NULL              : $ALTER_ELEMENTS_SYMBOL_NOT_NULL"
  echo "ALTER_ELEMENTS_SYMBOL_NOT_NULL              : $ALTER_ELEMENTS_SYMBOL_NOT_NULL"

  ALTER_PROPERTIES_ATOMIC_NUMBER_FOREIGN_KEY=$($PSQL "ALTER TABLE properties ADD FOREIGN KEY (atomic_number) REFERENCES elements(atomic_number);")
  echo "ALTER_PROPERTIES_ATOMIC_NUMBER_FOREIGN_KEY  : $ALTER_PROPERTIES_ATOMIC_NUMBER_FOREIGN_KEY"

  CREATE_TBL_TYPES=$($PSQL "CREATE TABLE types();")
  echo "CREATE_TBL_TYPES                            : $CREATE_TBL_TYPES"

  ADD_COLUMN_TYPES_TYPE_ID=$($PSQL "ALTER TABLE types ADD COLUMN type_id SERIAL PRIMARY KEY;")
  echo "ADD_COLUMN_TYPES_TYPE_ID                    : $ADD_COLUMN_TYPES_TYPE_ID"

  ADD_COLUMN_TYPES_TYPE=$($PSQL "ALTER TABLE types ADD COLUMN type VARCHAR(20) NOT NULL;")
  echo "ADD_COLUMN_TYPES_TYPE                       : $ADD_COLUMN_TYPES_TYPE"

  INSERT_COLUMN_TYPES_TYPE=$($PSQL "INSERT INTO types(type) SELECT DISTINCT(type) FROM properties;")
  echo "INSERT_COLUMN_TYPES_TYPE                    : $INSERT_COLUMN_TYPES_TYPE"

  ADD_COLUMN_PROPERTIES_TYPE_ID=$($PSQL "ALTER TABLE PROPERTIES ADD COLUMN type_id INT;")
  ADD_FOREIGN_KEY_PROPERTIES_TYPE_ID=$($PSQL "ALTER TABLE properties ADD FOREIGN KEY(type_id) REFERENCES types(type_id);")
  echo "ADD_COLUMN_PROPERTIES_TYPE_ID               : $ADD_COLUMN_PROPERTIES_TYPE_ID"
  echo "ADD_FOREIGN_KEY_PROPERTIES_TYPE_ID          : $ADD_FOREIGN_KEY_PROPERTIES_TYPE_ID"

  UPDATE_PROPERTIES_TYPE_ID=$($PSQL "UPDATE properties SET type_id = (SELECT type_id FROM types WHERE properties.type = types.type);")
  ALTER_COLUMN_PROPERTIES_TYPE_ID_NOT_NULL=$($PSQL "ALTER TABLE properties ALTER COLUMN type_id SET NOT NULL;")
  echo "UPDATE_PROPERTIES_TYPE_ID                   : $UPDATE_PROPERTIES_TYPE_ID"
  echo "ALTER_COLUMN_PROPERTIES_TYPE_ID_NOT_NULL    : $ALTER_COLUMN_PROPERTIES_TYPE_ID_NOT_NULL"

  UPDATE_ELEMENTS_SYMBOL=$($PSQL "UPDATE elements SET symbol=INITCAP(symbol);")
  echo "UPDATE_ELEMENTS_SYMBOL                      : $UPDATE_ELEMENTS_SYMBOL"

  ALTER_VARCHAR_PROPERTIES_ATOMIC_MASS=$($PSQL "ALTER TABLE PROPERTIES ALTER COLUMN atomic_mass TYPE VARCHAR(9);")
  UPDATE_FLOAT_PROPERTIES_ATOMIC_MASS=$($PSQL"UPDATE properties SET atomic_mass=CAST(atomic_mass AS FLOAT);")
  echo "ALTER_VARCHAR_PROPERTIES_ATOMIC_MASS        : $ALTER_VARCHAR_PROPERTIES_ATOMIC_MASS"
  echo "UPDATE_FLOAT_PROPERTIES_ATOMIC_MASS         : $UPDATE_FLOAT_PROPERTIES_ATOMIC_MASS"

  INSERT_ELEMENT_F=$($PSQL "INSERT INTO elements(atomic_number,symbol,name) VALUES(9,'F','Fluorine');")
  INSERT_PROPERTIES_F=$($PSQL "INSERT INTO properties(atomic_number,type,melting_point_celsius,boiling_point_celsius,type_id,atomic_mass) VALUES(9,'nonmetal',-220,-188.1,3,'18.998');")
  echo "INSERT_ELEMENT_F                            : $INSERT_ELEMENT_F"
  echo "INSERT_PROPERTIES_F                         : $INSERT_PROPERTIES_F"

  INSERT_ELEMENT_NE=$($PSQL "INSERT INTO elements(atomic_number,symbol,name) VALUES(10,'Ne','Neon');")
  INSERT_PROPERTIES_NE=$($PSQL "INSERT INTO properties(atomic_number,type,melting_point_celsius,boiling_point_celsius,type_id,atomic_mass) VALUES(10,'nonmetal',-248.6,-246.1,3,'20.18');")
  echo "INSERT_ELEMENT_NE                           : $INSERT_ELEMENT_NE"
  echo "INSERT_PROPERTIES_NE                        : $INSERT_PROPERTIES_NE"

  DELETE_PROPERTIES_1000=$($PSQL "DELETE FROM properties WHERE atomic_number=1000;")
  DELETE_ELEMENTS_1000=$($PSQL "DELETE FROM elements WHERE atomic_number=1000;")
  echo "DELETE_PROPERTIES_1000                      : $DELETE_PROPERTIES_1000"
  echo "DELETE_ELEMENTS_1000                        : $DELETE_ELEMENTS_1000"
  
  DELETE_COLUMN_PROPERTIES_TYPE=$($PSQL "ALTER TABLE properties DROP COLUMN type;")
  echo "DELETE_COLUMN_PROPERTIES_TYPE               : $DELETE_COLUMN_PROPERTIES_TYPE"
}

START_PROGRAM() {
  CHECK=$($PSQL "SELECT COUNT(*) FROM elements WHERE atomic_number=1000;")
  if [[ $CHECK -gt 0 ]]
  then
    FIX_DB
    clear
  fi
  MAIN_PROGRAM $1
}

START_PROGRAM $1