import os
import psycopg
from psycopg.rows import dict_row

def get_connection():
  return psycopg.connect(
    host=os.environ["POSTGRES_HOST"],
    port=os.environ["POSTGRES_PORT"],
    dbname=os.environ["POSTGRES_DB"],
    user=os.environ["POSTGRES_USER"],
    password=os.environ["POSTGRES_PASSWORD"],
    row_factory=dict_row,)

def get_items():
  """
  Return all items as a list of {"id", "name"} dicts.

  Returns
  -------
  list[dict]
    Returns all the records of `items` table in list format.
  """
  qry = "SELECT item_id AS id, item_name AS name FROM items ORDER BY item_id"

  with get_connection() as conn:
    with conn.cursor() as cur:
      return cur.execute(qry).fetchall()

def get_item(item_id):
  """_summary_
  Return one item from items table based on `item_id`.

  Parameters
  ----------
  item_id : int
    Primary key in `items` table.

  Returns
  -------
  dict
    Returns the fetched record in dictionary format.
  """
  qry = "SELECT item_id AS id, item_name AS name FROM items WHERE item_id = %s"

  with get_connection() as conn:
    with conn.cursor() as cur:
      return cur.execute(qry, (item_id,)).fetchone()

def write_item(item_name):
  """
  Insert an item and return it as {"id", "name"}.

  Parameters
  ----------
  item_name : str
    Name of the item to be written in `items` table.

  Returns
  -------
  dict
    Returns the written item in dictionary format.
  """
  qry = """
    INSERT INTO items (item_name)
    VALUES (%s)
    RETURNING item_id AS id, item_name AS name
  """

  with get_connection() as conn:
    with conn.cursor() as cur:
      return cur.execute(qry, (item_name,)).fetchone()

def update_item(item_id, item_name):
  """
  Update an item.

  Parameters
  ----------
  item_id : int
    Primary key in `items` table.
  item_name : str
    Value to replace the exising value in `item_name` column.

  Returns
  -------
  dict or None
    The updated item as {"id", "name"}, or None if `item_id` doesn't exist.
  """
  qry = """
  UPDATE items
  SET item_name = %s
  WHERE item_id = %s
  RETURNING item_id AS id, item_name AS name
  """

  with get_connection() as conn:
    with conn.cursor() as cur:
      return cur.execute(qry, (item_name, item_id,)).fetchone()

def delete_item(item_id):
  """
  Delete an item.

  Parameters
  ----------
  item_id : int
    Primary key in `items` table.

  Returns
  -------
  bool
    Indicator if delete operation is successful, or not.
  """
  qry = """
  DELETE FROM items
  WHERE item_id = %s
  """

  with get_connection() as conn:
    with conn.cursor() as cur:
      return cur.execute(qry, (item_id,)).rowcount > 0
