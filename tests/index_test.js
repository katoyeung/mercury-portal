import http from "k6/http";
import { sleep, check } from "k6";

export let options = {
  vus: 100, // Number of virtual users
  duration: "1m", // Test duration
};

export default function () {
  // Perform a simple GET request to the index page
  let res = http.get("http://localhost");

  // Check if the response returned a status code of 200
  check(res, {
    "is status 200": (r) => r.status === 200,
  });
}
