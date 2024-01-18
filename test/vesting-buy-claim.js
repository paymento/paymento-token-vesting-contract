const vesting = artifacts.require('MockedVesting');
const paymento = artifacts.require('Paymento'); 
const helper = require("../helpers/truffleTestHelper");

contract('MockedVesting', async () => {
    // deploy token and vesting contract in test setup
    let vestingContract;
    let pmo;
    let testAccount1;

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

    // Open Stage 2
    it('should open stage 2', async () => {
        await vestingContract.setStageOpen(2);
        assert.equal(await vestingContract.stageOpen(2), true);
    });

    // add account1 to whitelist
    it('should add account1 to whitelist', async () => {
        await vestingContract.addToWhitelist(2, testAccount1);
        assert.equal(await vestingContract.whitelistedAddresses(2, testAccount1), true);
    });

    // test if ETH/USDT price is eual to 2000USD
    it('Check ETH/USDT price', async () => {
        // mock the ETH price to $1800(1 ETH = 1800 USDT)
        await vestingContract.setLatestEthUsdPrice(1800.00 * 10 ** 8);
        assert.equal(await vestingContract.getLatestEthUsdPrice(), 1800 * 10 ** 8);
    });

    // Buy 1 ETH worth of tokens
    it('But 1 ETH worth of tokens', async () => {
        
        await vestingContract.buy(2, {from: testAccount1, value: 1 * 10 ** 18});

        // Cheking buyer's token balance
        const balance = await vestingContract.checkBalance(2, testAccount1);

        // 1 ETH = 1800 USDT
        // in Stage 2, 1 PMO = 0.18 USDT
        // 1 ETH = 1800/0.18 = 10000 PMO
        // in Stage 2, immadiate token transfer is 8%, so 10000*0.08 = 800 PMO
        assert.equal(balance, (10000-800) * 10 ** 18);
    });

    // Check passed days
    it('check passed days', async () => {
        const days = await vestingContract.getDaysPassedFromLastestClaim(2, testAccount1);
        assert.equal(days, 0);
    });

    // Check the amount of token user can claim
    it('Check the amount of token user can claim', async () => {
        const claimableTokens = await vestingContract.checkClaimableTokens(2, testAccount1);
        assert.equal(claimableTokens, 0);
    });

    // Mock passed days to 1 day
    it('Mock passed days to 1 day', async () => {
        await helper.advanceTimeAndBlock(24 * 60 * 60);
        const days = await vestingContract.getDaysPassedFromLastestClaim(2, testAccount1);
        assert.equal(days, 1);
    });

    // Check the amount of token user can claim
    it('Check the amount of token user can claim', async () => {
        const claimableTokens = await vestingContract.checkClaimableTokens(2, testAccount1);

        //in stage 2, vesting days is 480 days
        // so, 9200/480 = 19.166666666666
        assert.equal(claimableTokens, 19166666666666666666);
    });

    // Mock passed another day
    it('Mock passed another day', async () => {
        await helper.advanceTimeAndBlock(24 * 60 * 60);
        const days = await vestingContract.getDaysPassedFromLastestClaim(2, testAccount1);
        assert.equal(days, 2);
    });

    // Check the amount of token user can claim
    it('Check the amount of token user can claim', async () => {
        const claimableTokens = await vestingContract.checkClaimableTokens(2, testAccount1);

        //in stage 2, vesting days is 480 days
        // so, 9200 * 2/480 = 19.166666666666
        assert.equal(claimableTokens, 38333333333333333333);
    });

    // Mock passed 25 days
    it('Mock passed 25 days', async () => {
        await helper.advanceTimeAndBlock(25 * 24 * 60 * 60);
        const days = await vestingContract.getDaysPassedFromLastestClaim(2, testAccount1);
        assert.equal(days, 27);
    });

    // Check the amount of token user can claim
    it('Check the amount of token user can claim', async () => {
        const claimableTokens = await vestingContract.checkClaimableTokens(2, testAccount1);

        //in stage 2, vesting days is 480 days
        // so, 9200 * 27/480 = 19.166666666666
        assert.equal(claimableTokens, 517.5 * 10 ** 18);
    });

    // Claim tokens
    it('Claim tokens', async () => {
        await vestingContract.claimTokens(2, {from: testAccount1});
        const balance = await vestingContract.checkBalance(2, testAccount1);
        // 10000 is the first bought amount
        // 800 is immadiate transfer amount
        // 517.5 is claimed amount after 27 days
        assert.equal(balance, (10000-800-517.5) * 10 ** 18);

        pmoBalance = await pmo.balanceOf(testAccount1);
        //! 800 is immadiate transfer amount
        //! 517.5 is claimed amount after 27 days
        assert.equal(pmoBalance, (800 + 517.5) * 10 ** 18);
    });

    // Mock passed 480 days
    it('Mock passed 480 days', async () => {
        await helper.advanceTimeAndBlock(480 * 24 * 60 * 60);
        const days = await vestingContract.getDaysPassedFromLastestClaim(2, testAccount1);
        assert.equal(days, 480);
    });

    // Claim tokens
    it('Claim all tokens', async () => {
        await vestingContract.claimTokens(2, {from: testAccount1});
        const balance = await vestingContract.checkBalance(2, testAccount1);
        // In stage 2, vesting days is 480 days so all tokens should be claimed
        assert.equal(balance, 0);

        pmoBalance = await pmo.balanceOf(testAccount1);
        
        // 10000 is the first bought amount and all tokens should be claimed and transferred to user
        assert.equal(pmoBalance, 10000 * 10 ** 18);
    });

});