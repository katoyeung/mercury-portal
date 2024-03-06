import http from "k6/http";
import { sleep, check } from "k6";

export let options = {
  vus: 100,
  duration: "1m",
};

export default function () {
  let payload = JSON.stringify({
    username: "user",
    password: "password",
  });

  let params = {
    headers: {
      "Content-Type": "application/json",
    },
  };

  let res = http.post("http://localhost/login", payload, params);

  check(res, {
    "is status 200": (r) => r.status === 200,
  });
}
