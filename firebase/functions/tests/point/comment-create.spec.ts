import "mocha";
// import * as admin from "firebase-admin";

import { FirebaseAppInitializer } from "../firebase-app-initializer";

import { expect } from "chai";
import { Point } from "../../src/classes/point";
// import { EventName } from "../../src/interfaces/point.interface";
// import { Utils } from "../../src/utils/utils";
// import { Ref } from "../../src/utils/ref";
import { Test } from "../test";
// import { Category } from "../../src/classes/category";
// import { Ref } from "../../src/utils/ref";
// import { Post } from "../../src/classes/post";
import { User } from "../../src/classes/user";
import { EventName, pointEvent } from "../../src/interfaces/point.interface";
import { Utils } from "../../src/utils/utils";
import { Ref } from "../../src/utils/ref";
import { Comment } from "../../src/classes/comment";
// import { EventName } from "../../src/interfaces/point.interface";

new FirebaseAppInitializer();

describe("Point Comment Creation", () => {
  it("Within time test", async () => {
    // Create user, post, and increase point.
    const comment = await Test.createComment(undefined, "qna");

    await Point.commentCreate(comment, comment.id);
    const commentWithPoint = await Comment.get(comment.id);

    // Create post and increase point again.
    const anotherComment = await Test.createComment(comment.uid, "qna", {});
    await Point.commentCreate(anotherComment, anotherComment.id);

    // Two post create but only one got point.
    // Prove it.
    const point = await User.point(comment.uid);
    expect(point).equals(commentWithPoint.point);

    // Change within and increase point.
    // Set post create `within` time to 1 seconds. and wait 2 seconds.
    pointEvent[EventName.commentCreate].within = 1;
    await Utils.delay(2000);
    const c = await Test.createComment(comment.uid, "qna", {});
    await Point.commentCreate(c, c.id);
    const cWithPoint = await Comment.get(c.id);

    const increased = await User.point(comment.uid);
    expect(increased).equals((commentWithPoint?.point ?? 0) + (cWithPoint.point ?? 0));
    // console.log(c.uid, increased);

    const snapshot = await Ref.pointHistoryCol(comment.uid).get();
    expect(snapshot.size).equals(2);
  });
});
