const helper = require("../helpers/truffleTestHelper");

it("should advance the blockchain forward a block", async () =>{
    const originalBlockHash = (await web3.eth.getBlock('latest')).hash;
    console.log("originalBlockHash", originalBlockHash);

    let newBlockHash = await helper.advanceBlock();
    console.log("newBlockHash", newBlockHash);

    assert.notEqual(originalBlockHash, newBlockHash);
});

it("should be able to advance time and block together", async () => {
    const advancement = 86400; // 1 day in seconds
    const originalBlock = await web3.eth.getBlock('latest');
    const newBlock = await helper.advanceTimeAndBlock(advancement);
    const timeDiff = newBlock.timestamp - originalBlock.timestamp;
    
    console.log("timeDiff", timeDiff, "new block time:", newBlock.timestamp);

    assert.isTrue(timeDiff >= advancement);
});