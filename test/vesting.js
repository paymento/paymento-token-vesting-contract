const vesting = artifacts.require('VestingContract');
const helper = require("../helpers/truffleTestHelper");

// test deploy
contract('VestingContract', async () => {
    
    // deploy the vesting contract in test setup
    let vestingContract;
    before(async () => {
        vestingContract = await vesting.new('0x8514F908eE2B47a7f83c60A564d2Acf8f3F0baEC', '0x8514F908eE2B47a7f83c60A564d2Acf8f3F0baEC');
    });

    // test if vesting stage 0 is correctly set
    it('Check stage 0 values', async () => {
        const stage = await vestingContract.vestingStages(0);
        assert.equal(stage.tokenCount, 17500000 * 10 ** 18);
        assert.equal(stage.price, 75);
        assert.equal(stage.immadiateTokenReleasePercentage, 5);
        assert.equal(stage.vestingDays, 720);
    });

    // test if stage 0 is close
    it('Check stage 0 status', async () => {
        assert.equal(await vestingContract.stageOpen(0), false);

        await vestingContract.setStageOpen(0);

        assert.equal(await vestingContract.stageOpen(0), true);
    });

    // TEST HELPER FUNCTIONS
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
});