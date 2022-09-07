import "mocha";

import { FirebaseAppInitializer } from "../firebase-app-initializer";
// import { Test } from "../../src/classes/test";
// import { Utils } from "../../src/classes/utils";

import { Messaging } from "../../src/classes/messaging";
import { expect } from "chai";
import { Test } from "../test";
import { HttpsError } from "firebase-functions/v1/auth";

new FirebaseAppInitializer();

describe("Send message to token", () => {
  it("Send a message to a token", async () => {
    try {
      const res = await Messaging.sendMessageToTokens(
        [Test.token],
        { title: "from cli", body: "to iphone. is that so?" },
        {} as any
      );
      console.log(JSON.stringify(res));
      expect("0").to.be.an("string");
    } catch (e) {
      console.log((e as HttpsError).code, (e as HttpsError).message);
      expect.fail("Must succeed on sending a message to a token");
    }
  });
});
