function _start() {
  console.log("trying to receive");
  let m = sub.open("my-messaging");
  console.log("messaging opened");
  let pubsub = sub.subscribe(m, "t-order-ingress-wasm");
  console.log("subscribed", pubsub);
  let message = sub.receive(m, pubsub);
  console.log("received");
  if (typeof message == "object") {
    if (message.byteLength > 0) {
      console.log(String.fromCharCode.apply(null, new Uint8Array(message)));
    }
  } else {
    console.log(message);
  }
}
