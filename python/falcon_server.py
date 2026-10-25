import falcon
import falcon.asgi
import asyncio
import logging
from logging_config import configure_logging
from db import get_items, write_item

configure_logging()
logger = logging.getLogger(__name__)

"""
This module uses Falcon to create the API endpoints.
"""

class HealthResource:
  """
  API health check.
  """
  async def on_get(self, req, resp):
    """
    Usage:
      curl http://localhost:8080/api/healthz
    """
    resp.media = {"status": "ok"}

class ItemsResource:
  async def on_get(self, req, resp):
    """
    Collection of items.
    Usage:
      curl http://localhost:8080/api/items
    """
    logger.info("Getting all items")
    resp.media = await asyncio.to_thread(get_items)

  async def on_post(self, req, resp):
    """
    Creates an item.
    Usage:
      curl -X POST -H "Content-Type: application/json" \\
        -d '{"name": "value"}' http://localhost:8080/api/items
    """
    data = await req.get_media()
    name = data.get("name") if isinstance(data, dict) else None
    if not isinstance(name, str) or not name.strip():
      raise falcon.HTTPBadRequest(
        title="Invalid item",
        description="'name' must be a non-empty string")
    name = name.strip()
    logger.info("Creating new item: %s", name)
    resp.status = falcon.HTTP_201
    resp.media = await asyncio.to_thread(write_item, name)


app = falcon.asgi.App()
app.add_route("/api/healthz", HealthResource())
app.add_route("/api/items", ItemsResource())