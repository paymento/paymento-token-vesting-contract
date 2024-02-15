const vesting = artifacts.require('MockedVesting');
const paymento = artifacts.require('Paymento'); 
const helper = require("../helpers/truffleTestHelper");

contract('MockedVesting', async () => {
    // deploy token and vesting contract in test setup
    let vestingContract;
    let pmo;
    let testAccount1;
    let testStage = 4;

    before(async () => {
        pmo = await paymento.new();
        // deploy the vesting contract
        vestingContract = await vesting.new(pmo.address, '0x8514F908eE2B47a7f83c60A564d2Acf8f3F0baEC');

        // get ganache account 1
        testAccount1 = (await web3.eth.getAccounts())[1];
    });

    //Transfer 1M tokens to vesting contract
    it('should transfer 1M tokens to vesting contract', async () => {
        await pmo.transfer(vestingContract.address, BigInt(1000000 * 10 ** 18));
        const balance = await pmo.balanceOf(vestingContract.address);
        assert.equal(balance, 1000000 * 10 ** 18);
    });

    // Open Stage
    it('should open stage', async () => {
        await vestingContract.setStageOpen(testStage);
        assert.equal(await vestingContract.stageOpen(testStage), true);
    });

    it('Allocate 1000 tokens to testAccount1', async () => {
        await vestingContract.allocateTokens(testStage, testAccount1, BigInt(1000 * 10 ** 18));

        // get balance after allocation
        const balance = await vestingContract.checkBalance(testStage, testAccount1);

        //! Check if the allocation is successful
        // get the stage settings
        const stage = await vestingContract.vestingStages(testStage);
        const expectedBalance = 1000 - (1000 * stage.immadiateTokenReleasePercentage / 100);
        assert.equal(balance, expectedBalance * 10 ** 18);
    });

    it('Check current user token balance testAccount1', async () => {
        const pmoBalance = await pmo.balanceOf(testAccount1);

        const stage = await vestingContract.vestingStages(testStage);
        const expectedBalance = 1000 * stage.immadiateTokenReleasePercentage / 100;
        assert.equal(pmoBalance, expectedBalance * 10 ** 18);
    });

    // Check passed days
    it('check passed days', async () => {
        const days = await vestingContract.getDaysPassedFromLastestClaim(testStage, testAccount1);
        assert.equal(days, 0);
    });

    // Check the amount of token user can claim
    it('Check the amount of token user can claim', async () => {
        const claimableTokens = await vestingContract.checkClaimableTokens(testStage, testAccount1);
        assert.equal(claimableTokens, 0);
    });

    // Mock passed days to 1 day
    it('Mock passed days to 1 day', async () => {
        await helper.advanceTimeAndBlock(24 * 60 * 60);
        const days = await vestingContract.getDaysPassedFromLastestClaim(testStage, testAccount1);
        assert.equal(days, 1);
    });

    // Check the amount of token user can claim
    it('Check the amount of token user can claim', async () => {
        const claimableTokens = await vestingContract.checkClaimableTokens(testStage, testAccount1);

        const stage = await vestingContract.vestingStages(testStage);

        const vestingDays = stage.vestingDays;

        // number of tokens to be claimed
        const allocatedBalance = 1000 - (1000 * stage.immadiateTokenReleasePercentage / 100);
        // calculate the claimable tokens
        const x = allocatedBalance / vestingDays;

        assert.equal(claimableTokens, x * 10 ** 18);
    });

    // Mock passed 25 days
    it('Mock passed 25 days', async () => {
        await helper.advanceTimeAndBlock(25 * 24 * 60 * 60);
        const days = await vestingContract.getDaysPassedFromLastestClaim(testStage, testAccount1);
        assert.equal(days, 26);
    });

    // Check the amount of token user can claim
    it('Check the amount of token user can claim after 26 days', async () => {
        const claimableTokens = await vestingContract.checkClaimableTokens(testStage, testAccount1);

        const stage = await vestingContract.vestingStages(testStage);

        const vestingDays = stage.vestingDays;

        // number of tokens to be claimed
        const allocatedBalance = 1000 - (1000 * stage.immadiateTokenReleasePercentage / 100);
        // calculate the claimable tokens
        const x = allocatedBalance / vestingDays * 26;

        assert.equal(claimableTokens, x * 10 ** 18);
    });

    // Mock passed 360 days
    it('Mock passed 360 days', async () => {
        await helper.advanceTimeAndBlock(360 * 24 * 60 * 60);
        const days = await vestingContract.getDaysPassedFromLastestClaim(testStage, testAccount1);
        assert.equal(days, 360+26);
    });

    // Check the amount of token user can claim
    it('Check the amount of token user can claim after 386 days', async () => {
        const claimableTokens = await vestingContract.checkClaimableTokens(testStage, testAccount1);

        const stage = await vestingContract.vestingStages(testStage);

        // number of tokens to be claimed
        const allocatedBalance = 1000 - (1000 * stage.immadiateTokenReleasePercentage / 100);
        // calculate the claimable tokens
        const x = allocatedBalance / stage.vestingDays * 386;

        assert.equal(claimableTokens, x * 10 ** 18);
    });

    // Claim tokens
    it('Claim tokens', async () => {
        const stage = await vestingContract.vestingStages(testStage);
        
        //! This is the amount user received immadiately after allocation
        const immadiateClaim = (1000 * 10 ** 18) * stage.immadiateTokenReleasePercentage / 100;

        // Totalvesting balance = allocation - immadiate transfer
        const vestingBalance = (1000 * 10 ** 18) - immadiateClaim;

        // User claims tokens after 386 days
        await vestingContract.claimTokens(testStage, {from: testAccount1});

        // Claimed right now by calling above function
        const claimedRightNow = vestingBalance / stage.vestingDays * 386;

        // Check the remaining vesting balance after claim
        const balance = await vestingContract.checkBalance(testStage, testAccount1);
        assert.equal(balance, vestingBalance - claimedRightNow);

        // Check the user token balance
        pmoBalance = await pmo.balanceOf(testAccount1);
        assert.equal(pmoBalance, immadiateClaim + claimedRightNow);
    });

});