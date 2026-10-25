import logging
from fastapi import FastAPI, APIRouter, status, HTTPException
from pydantic import BaseModel, ConfigDict, Field
from db import get_items, get_item, write_item, update_item, delete_item
from logging_config import configure_logging

configure_logging()
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api")


class ItemIn(BaseModel):
  """Request body for creating an item."""
  model_config = ConfigDict(str_strip_whitespace=True)
  name: str = Field(min_length=1)


class Item(BaseModel):
  """An item as returned by the API."""
  id: int
  name: str


@router.get("/healthz")
def healthz():
  """
  API health check.

  Usage:
    curl http://localhost:8080/api/healthz
  """
  return {"status": "ok"}


@router.get("/items", response_model=list[Item])
def read_items():
  """
  Get all items.

  Usage:
    curl http://localhost:8080/api/items

  Returns
  -------
  list[dict]
    SQL query result from `items` table, represents all records.
  """
  logger.info("Getting all items")
  items = get_items()

  return items

@router.get("/items/{item_id}")
def read_item(item_id: int) -> dict:
  """
  Get a single item.

  Usage:
    curl http://localhost:8080/api/items/1

  Parameters
  ----------
  item_id : int
    Primary key of `items` table in the db (taken from the URL path).

  Returns
  -------
  dict
    SQL query result from `items` table, represents a single record.
  """
  msg = "Getting item with ID: %s"
  logger.info(msg, item_id)

  item = get_item(item_id)

  return item

@router.post("/items", response_model=Item, 
  status_code=status.HTTP_201_CREATED)
def create_item(item: ItemIn):
  """
  Create an item.

  Usage:
    curl -X POST -H "Content-Type: application/json" \\
      -d '{"name": "value"}' http://localhost:8080/api/items

  Parameters
  ----------
  item : ItemIn
    Request body container the `name`.
  """
  logger.info("Creating new item: %s", item.name)
  created = write_item(item.name)

  if created is None:
    raise HTTPException(status_code=404, detail="Item not found.")
  
  return created

@router.put("/items/{item_id}", response_model=Item)
def replace_item(item_id: int, item: ItemIn):
  """
  Update an item.

  Replaces the name of an existing item and returns the updated item.

  Usage:
    curl -X PUT -H "Content-Type: application/json" \\
      -d '{"name": "new name"}' http://localhost:8080/api/items/1

  Parameters
  ----------
  item_id : int
    Primary key of the item to update (taken from the URL path).
  item: Item
    Request body containing the new `name`.

  Returns
  -------
  Item
    The updated item.
  """
  logger.info("Updating item: {item_id}")
  updated = update_item(item_id, item.name)

  if updated is None:
    raise HTTPException(status_code=404, detail="Item not found.")
  
  return updated

@router.delete("/items/{item_id}")
def remove_item(item_id: int):
  """
  Deletes an item.

  Usage:
    curl -X DELETE  http://localhost:8080/api/items/1

  Parameters
  ----------
  item_id : int
    Primary key of the item to delete (taken from the URL path).

  Returns
  -------
  deleted : bool
    Indicator if the item is deleted, or not.
  """
  logger.info("Deleting item with ID: {item_id}")
  deleted = delete_item(item_id)

  if deleted is False:
    raise HTTPException(status_code=404, detail="Item not found.")
  
  return deleted


app = FastAPI()
app.include_router(router)