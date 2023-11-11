function _start() {
  console.log("trying to send");
  pub.publish(pub.open("my-messaging"), "TESTMESSAGE", "t-order-ingress-wasm");
  console.log("OK?");
}
