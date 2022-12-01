const DAO = artifacts.require("DAO.sol");
const LOG = false;

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

contract("DAO Test 2", (accounts) => {
  it("should deploy the DAO contract", async () => {
    let dao = await DAO.deployed({ from: accounts[0] });
    assert.isOk(dao);
  });

  it("should allow 4 users to request tokens", async () => {
    let dao = await DAO.deployed();
    await dao.userReqToken(1e5, { from: accounts[1], value: 1e5 });
    await dao.userReqToken(2e5, { from: accounts[2], value: 2e5 });
    await dao.userReqToken(3e5, { from: accounts[3], value: 3e5 });
    await dao.userReqToken(4e5, { from: accounts[4], value: 4e5 });
  });


  it("should not allow DAO initialization", async () => {
    let dao = await DAO.deployed();
    let prevBalance = await dao.balanceOf(accounts[4], { from: accounts[4] });
    assert.equal(prevBalance.words[0], 4000);
    await dao.userRevokeToken({ from: accounts[4] });
    await dao.balanceOf(accounts[4], { from: accounts[4] });
    // await sleep(5 * 1000);
    // await dao.initDAO({ from: accounts[0], value: 4e6});
    
    // Init dao should fail
    try {
      await dao.initDAO({ from: accounts[0], value: 4e5});
      assert.isOk(false);
    } catch (e) {
      assert.isOk(e);
    }

    let afterBalance = await dao.balanceOf(accounts[4], { from: accounts[4] });
    assert.equal(afterBalance.words[0], 0);
  });


  // it("should allow proposals to vote on from a user", async () => {
  //   let dao = await DAO.deployed();

  //   await dao.propose("Tesla", accounts[5], { from: accounts[2] });
  //   await dao.propose("Mercedes", accounts[6], { from: accounts[2] });
  //   await dao.propose("Ferrari", accounts[7], { from: accounts[2] });
  //   await dao.propose("Mitsubushi", accounts[8], { from: accounts[2] });
  //   await dao.endPropose({from: accounts[2]});
  // });


  // it("should allow secret bids after proposal period is over", async () => {
  //   let dao = await DAO.deployed();

  //   // // change according to the respective parameter
  //   // await sleep(10 * 1000);
  //   let secrets = [await dao.generateBidHash.call(rankings[0], { from: accounts[1] }),
  //   await dao.generateBidHash.call(rankings[1], { from: accounts[2] }),
  //   await dao.generateBidHash.call(rankings[2], { from: accounts[3] })]

  //   await dao.secretBid(secrets[0], { from: accounts[1] });
  //   await dao.secretBid(secrets[1], { from: accounts[2] });
  //   await dao.secretBid(secrets[2], { from: accounts[3] });

  // });

  // it("should verify minimum quorum participation", async () => {
  //   let dao = await DAO.deployed();
  //   // await sleep(10 * 1000);

  //   let ok = await dao.verifyQuorum({ from: accounts[0] });
  //   assert(ok);
  // });

  // it("should successfully verify the secret bids", async () => {
  //   let dao = await DAO.deployed();

  //   // await sleep(10 * 1000);

  //   await dao.revealBid(rankings[0], { from: accounts[1] });
  //   await dao.revealBid(rankings[1], { from: accounts[2] });
  //   await dao.revealBid(rankings[2], { from: accounts[3] });

  //   // await sleep(10 * 1000);

  //   let ok = await dao.verifyAllBids({ from: accounts[0] });
  //   assert(ok);
  // });

  // it("should decide the winner and transfer funds to it", async () => {
  //   let dao = await DAO.deployed();

  //   // await sleep(10 * 1000);

  //   await dao.takeDecision({ from: accounts[0] });
  //   let winner = await dao.currWinner();
  //   console.log(winner);
  //   assert.equal(winner, "Mercedes");
  // });


  // Log all events
  it("should log all events", async () => {
    let dao = await DAO.deployed();
    if (LOG) {
      let events = await dao.getPastEvents("allEvents", { fromBlock: 0, toBlock: "latest",});
      console.log(events);
    }
  });

});
