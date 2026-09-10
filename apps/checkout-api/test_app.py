import unittest

from app import app


class CheckoutApiTest(unittest.TestCase):
    def setUp(self) -> None:
        self.client = app.test_client()

    def test_healthz(self) -> None:
        response = self.client.get("/healthz")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["status"], "ok")

    def test_checkout(self) -> None:
        response = self.client.get("/api/v1/checkout")
        self.assertEqual(response.status_code, 200)
        self.assertIn("order_id", response.get_json())

    def test_metrics(self) -> None:
        self.client.get("/")
        response = self.client.get("/metrics")
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"http_requests_total", response.data)


if __name__ == "__main__":
    unittest.main()
