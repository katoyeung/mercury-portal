import http from "k6/http";
import { check } from "k6";

export let options = {
  vus: 100, // Simulate 100 virtual users
  duration: "1m", // Running the test for 1 minute
};

export default function () {
  let params = {
    headers: {
      Authorization: "Bearer xxx",
    },
  };

  let res = http.get("http://localhost/", params);

  check(res, {
    "is status 200": (r) => r.status === 200,
  });
}
