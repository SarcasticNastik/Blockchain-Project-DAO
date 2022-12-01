const DAO = artifacts.require("DAO.sol");
const LOG = true;

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

contract("DAO Test 1", (accounts) => {
  let initialBalance = web3.eth.getBalance(accounts[0]);
  it("should deploy the DAO contract", async () => {
    console.log(await initialBalance)
    let dao = await DAO.deployed({from: accounts[0]});
    assert.isOk(dao);
  });

  it("should allow 4 users to request tokens", async () => {
    let dao = await DAO.deployed();
    await dao.userReqToken(1e6, { from: accounts[1], value: 1e6 });
    await dao.userReqToken(2e7, { from: accounts[2], value: 2e7 });
    await dao.userReqToken(3e8, { from: accounts[3], value: 3e8 });
    await dao.userReqToken(4e9, { from: accounts[4], value: 4e9 });
  });

  it("should allow 1 revoke for allowed token on DAO initialization", async () => {
    let dao = await DAO.deployed();
    let prevBalance = await dao.balanceOf(accounts[4], { from: accounts[4] });
    await dao.userRevokeToken({ from: accounts[4] });
    await dao.balanceOf(accounts[4], { from: accounts[4] });
    
    await sleep(10 * 1000);
    await dao.initDAO({from: accounts[0]});

    console.log("INITDAO Issue not resolved")
    
    let afterBalance = await dao.balanceOf(accounts[4], { from: accounts[4] });
    console.log(prevBalance, afterBalance);
  });


  // Log all events
  it("should log all events", async () => {
    let dao = await DAO.deployed();
    if (LOG) {
      let events = await dao.getPastEvents("allEvents", {
        fromBlock: 0,
        toBlock: "latest",
      });
      console.log(events);
    }
  });

});
