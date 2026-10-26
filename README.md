# PostgreSQL playground

A PostgreSQL playground you can use to practice SQL.

- `db/sql/init/NN_*.sql`: creates each exercise's tables and data
- `db/sql/solutions/NN_*.sql`: your answer to each exercise, one file per exercise
- `db/bin/init_db.sh`: runs the init scripts inside the database container

Run all commands from the repo root. `make` is the only command you need.

## Setup

    make run        # initialise the database on first run, then start the stack
    make connect-db # open a psql shell in the database container

`make run` loads every script in `db/sql/init/` the first time and skips it on later runs. The stack must be running before `make connect-db` works.

To start over:

    make wipe-db    # delete the database files; the next `make run` starts from scratch
    make stop       # stop and remove the containers
    make clean      # also remove volumes and locally built images

Run `make wipe-db` after editing a script in `db/sql/init/`.

## Adding your answers

Each exercise has a file in `db/sql/solutions/` with the same name as its init script. For exercise 04, `db/sql/init/04_sessionization.sql` pairs with `db/sql/solutions/04_sessionization.sql`.

1. Read the task in the exercise's init script or the exercise list.
2. Open the matching file in `db/sql/solutions/`.
3. Write your query in it. The tables are in the `public` schema, so no setup is needed:

       SELECT ...;

4. Run it and compare the result with the expected output:

       make run-solution FILE=04_sessionization.sql

Keep one exercise per file, and end every query with a semicolon.

## Make targets

| Target | What it does |
| --- | --- |
| `make run` | Initialise the database if needed, then start the stack |
| `make connect-db` | psql shell in the database container |
| `make run-solution FILE=<name>.sql` | Run one file from `db/sql/solutions/` and print the result |
| `make init-db` | Run the init scripts only |
| `make wipe-db` | Re-run the init scripts / delete the database files |
| `make logs [SERVICE=python]` | Stream container logs |
| `make stop` / `make clean` | Stop everything / also remove volumes and images |

## Options

`API_PORT`, `PROJECT_NAME`, `SERVICE` and `FILE` can be overridden, e.g. `make run API_PORT=9000`.

## Note

- The python API server is not currently used.
- I will add more SQL exercises in the future as my SQL skills improved.