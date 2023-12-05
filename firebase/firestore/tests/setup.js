// load firebase-functions-test SDK
const firebase = require("@firebase/testing");

// Firebase project that the tests connect to.
const TEST_PROJECT_ID = "withcenter-test-2";

const a = { uid: "uid-A", email: "apple@gmail.com" };
const b = { uid: "uid-B", email: "banana@gmail.com" };
const c = { uid: "uid-C", email: "cherry@gmail.com" };
const d = { uid: "uid-D", email: "durian@gmail.com" };
const e = { uid: "uid-E", email: "eggplant@gmail.com" };

const postsColName = "posts";
const categoriesColName = "categories";
const commentsColsName = "comments";
const chatsColName = "chats";
const usersColName = "users";

// Connect to Firestore with a user permission.
function db(auth = null) {
  return firebase
    .initializeTestApp({ projectId: TEST_PROJECT_ID, auth: auth })
    .firestore();
}

// Connect to Firestore with admin permssion. This will pass all the rules.
function admin() {
  return firebase
    .initializeAdminApp({ projectId: TEST_PROJECT_ID })
    .firestore();
}

/**
 * Returns fake chat room data
 *
 *
 * By default,
 *  - createdAt: new Date()
 *  - group: false
 *  - open: false
 *  - no uid.
 *
 *
 * @param {*} options
 * @returns returns chat room data
 *
 * @example
 *  - tempChatRoomData({ master: a.uid, users: [a.uid, b.uid] }
 */
function tempChatRoomData(options = {}) {
  return Object.assign(
    {},
    {
      createdAt: new Date(),
      group: false,
      open: false,
    },
    options
  );
}

/**
 *
 * @param {*} masterAuth
 * @param {*} options
 * @returns chat room ref
 * @example
 * ```
 * const roomRef = await createChatRoom(a, { master: a.uid, users: [a.uid, b.uid] }); // create a 1:1 chat room by A(master) with B.
 * ```
 * The above example creates a chat room by A with B. It is short for:
 * ```
 * const roomRef = await db(a).collection(chatsColName).add(tempChatRoomData({ master: a.uid, users: [a.uid, b.uid] }));
 * ```
 */
function createChatRoom(masterAuth, options = {}) {
  return db(masterAuth).collection(chatsColName).add(tempChatRoomData(options));
}

async function createOpenGroupChat(masterAuth) {
  return await createChatRoom(a, {
    master: a.uid,
    users: [a.uid],
    open: true,
    group: true,
  });
}

/**
 * Chat invite
 *
 *
 * @param {*} a the auth of the user who invites
 * @param {*} b the auth of the user who is being invited.
 */
async function invite(a, b, roomId) {
  await db(a)
    .collection(chatsColName)
    .doc(roomId)
    .update({ users: firebase.firestore.FieldValue.arrayUnion(b.uid) });
}

/**
 * Chat block
 *
 *
 * @param {*} blockerAuth the auth of the user who blocks
 * @param {*} blockedAuth the auth of the user who is being blocked.
 */
async function block(blockerAuth, blockedAuth, roomId) {
  await db(blockerAuth)
    .collection(chatsColName)
    .doc(roomId)
    .update({
      blockedUsers: firebase.firestore.FieldValue.arrayUnion(blockedAuth.uid),
    });
}

/**
 * Chat unblock
 *
 *
 * @param {*} unblockerAuth the auth of the user who blocks
 * @param {*} blockedAuth the auth of the user who is being blocked.
 */
async function unblock(unblockerAuth, blockedAuth, roomId) {
  await db(unblockerAuth)
    .collection(chatsColName)
    .doc(roomId)
    .update({
      blockedUsers: firebase.firestore.FieldValue.arrayRemove(blockedAuth.uid),
    });
}

/**
 * Chat Set as Moderator
 *
 *
 * @param {*} setterAuth the auth of the user who sets the moderator
 * @param {*} userAuth the auth of the user who is being added as moderator.
 */
async function setAsModerator(setterAuth, userAuth, roomId) {
  await db(setterAuth)
    .collection(chatsColName)
    .doc(roomId)
    .update({
      moderators: firebase.firestore.FieldValue.arrayUnion(userAuth.uid),
    });
}

async function createCategory(options = {}) {
  const id =
    (options?.prefix ?? "") +
    "test-category" +
    Date.now() +
    Math.floor(Math.random() * 10000);

  // create category
  await admin().collection(categoriesColName).doc(id).set({
    name: id,
    createdAt: firebase.firestore.FieldValue.serverTimestamp(),
    updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
    // TODO - change addBy to uid.
    createdBy: "test-uid-admin",
  });

  return admin().collection(categoriesColName).doc(id);
}

// create post
// example
// ```
// const postRef = await createPost({ auth: a, prefix: "likes-"});
// ```
async function createPost(options = {}) {
  if (!options.auth) {
    options.auth = a;
  }
  const categoryRef = await createCategory(options);

  // create post
  const postRef = await db(options.auth).collection(postsColName).add({
    categoryId: categoryRef.id,
    title: "Sample Title",
    content: "Sample Content",
    uid: options.auth.uid,
    createdAt: firebase.firestore.FieldValue.serverTimestamp(),
    updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
    likes: [],
  });

  return postRef;
}

/**
 * Creates a random user with options.data on options.col collection.
 * 
 * By default, it creates a random user with random uid and email under `/users` collection.
 * Use this to create a random user.
 * 
 *  Add create or update to user collection
 * 
 * @param {*} user 
 * @param {*} options 
 * 
 * Example of creating a random user with random uid and email under `/users` collection.
 * await createUser();
 * 
 * Example of creating a collection "/only-adding/{uid}" with data { uid: b.uid, name: "abc" } with user b's auth.
 * 
 * await createUser(b, {
      col: "only-adding",
      data: {
        uid: b.uid,
        name: "abc",
      },
    });

 * @return user uid as string.
 */
async function createUser(user, options = {}) {
  if (!user) {
    user = {
      uid: randomString(),
      email: randomString() + "@gmail.com",
    };
  }

  await db(user)
    .collection(options.col ?? usersColName)
    .doc(user.uid)
    .set(
      options.data ?? {
        uid: user.uid,
        email: user.email,
        followers: [],
        following: [],
      }
    );

  return user.uid;
}

// create a function named 'randomString' which returns a random string.
function randomString() {
  return Math.random().toString(36).substring(7);
}
exports.createUserOnlyXxx = async (data = {}) => {
  const uid = randomString();
  await db({ uid, email: uid + "@gmail.com" })
    .collection("only-xxx")
    .doc(uid)
    .set({
      uid: uid,
      ...data,
    });
  return uid;
};

exports.userDoc = (uid) => {
  const auth = { uid, email: uid + "@gmail.com" };
  return db(auth).collection(usersColName).doc(uid);
};

exports.db = db;
exports.admin = admin;
exports.tempChatRoomData = tempChatRoomData;
exports.createChatRoom = createChatRoom;
exports.a = a;
exports.b = b;
exports.c = c;
exports.d = d;
exports.postsColName = postsColName;
exports.categoriesColName = categoriesColName;
exports.commentsColsName = commentsColsName;
exports.chatsColName = chatsColName;
exports.usersColName = usersColName;
exports.TEST_PROJECT_ID = TEST_PROJECT_ID;
exports.createOpenGroupChat = createOpenGroupChat;
exports.invite = invite;
exports.block = block;
exports.unblock = unblock;
exports.setAsModerator = setAsModerator;
exports.createCategory = createCategory;
exports.createPost = createPost;
exports.createUser = createUser;
exports.randomString = randomString;
