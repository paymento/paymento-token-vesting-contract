const vesting = artifacts.require('MockedVesting');
const paymento = artifacts.require('Paymento'); 

// test deploy
contract('MockedVesting', async () => {
    // deploy token and vesting contract in test setup
    let vestingContract;
    let pmo;
    let testAccount1;
    
    before(async () => {
        
    });

    beforeEach(async () => {
        pmo = await paymento.new();
        // deploy the vesting contract
        vestingContract = await vesting.new(pmo.address, '0x8514F908eE2B47a7f83c60A564d2Acf8f3F0baEC');

        // get ganache  account 1
        testAccount1 = (await web3.eth.getAccounts())[1];
    });

    it('Transfer 1M to vesting contract', async () => {

        // transfer 1M tokens to vesting contract
        await pmo.transfer(vestingContract.address, BigInt(1000000 * 10 ** 18));

        // check if vesting contract has 1M tokens
        const balance = await pmo.balanceOf(vestingContract.address);
        assert.equal(balance, 1000000 * 10 ** 18);
    });

    // test if vesting stage 0 is correctly set
    it('Check stage 0 values', async () => {
        const stage = await vestingContract.vestingStages(0);
        assert.equal(stage.tokenCount, 17500000 * 10 ** 18);
        assert.equal(stage.price, 75);
        assert.equal(stage.immadiateTokenReleasePercentage, 5);
        assert.equal(stage.vestingDays, 720);
    });

    //#region Check setStageOpen and setStageClose function
    // function setStageOpen should fail if not called by owner
    it('Check setStageOpen function calling by not owner', async () => {
        try {
            await vestingContract.setStageOpen(0, {from: '0x077D360f11D220E4d5D831430c81C26c9be7C4A4'});
            assert.fail();
        } catch (error) {
            assert.ok(/revert/.test(error.message));
        }
    });

    // test stage 0 status
    it('Check setStageOpen and Close function', async () => {
        assert.equal(await vestingContract.stageOpen(0), false);

        await vestingContract.setStageOpen(0);

        assert.equal(await vestingContract.stageOpen(0), true);

        await vestingContract.setStageClose(0);

        assert.equal(await vestingContract.stageOpen(0), false);
    });

    // test stage 8 status
    it('Check setStageOpen and Close function', async () => {
        assert.equal(await vestingContract.stageOpen(8), false);

        await vestingContract.setStageOpen(8);

        assert.equal(await vestingContract.stageOpen(8), true);

        await vestingContract.setStageClose(8);

        assert.equal(await vestingContract.stageOpen(8), false);
    });
    //#endregion

    //#region Test TotalTokenForStage
    // test if TotalTokenForStage is correct
    it('Check TotalTokenForStage function', async () => {
        assert.equal(await vestingContract.getTotalTokenForStage(0), 17500000 * 10 ** 18);
        assert.equal(await vestingContract.getTotalTokenForStage(1), 24500000 * 10 ** 18);
        assert.equal(await vestingContract.getTotalTokenForStage(8), 52500000 * 10 ** 18);
    });

    // getTotalTokenForStage call be called by anyone
    it('Check getTotalTokenForStage function calling by not owner', async () => {
        assert.equal(await vestingContract.getTotalTokenForStage(0, {from: '0x077D360f11D220E4d5D831430c81C26c9be7C4A4'}), 17500000 * 10 ** 18);
    });
    //#endregion

    //#region Test getTokensAvailableToBuy
    // test if getTokensAvailableToBuy is correct
    it('Check if return value of getTokensAvailableToBuy function are correct before any purchase', async () => {
        assert.equal(await vestingContract.getTokensAvailableToBuy(0), 17500000 * 10 ** 18);
        assert.equal(await vestingContract.getTokensAvailableToBuy(1), 24500000 * 10 ** 18);
        assert.equal(await vestingContract.getTokensAvailableToBuy(8), 52500000 * 10 ** 18);
    });
    //#endregion

    //#region Test ETH/USDT Price
    // test if ETH/USDT price is eual to 200000000000
    it('Check ETH/USDT price', async () => {
        assert.equal(await vestingContract.getLatestEthUsdPrice(), 200000000000);
    });

    // Change the price and test the value again
    it('Change ETH/USDT price', async () => {
        await vestingContract.setLatestEthUsdPrice(100000000000);

        assert.equal(await vestingContract.getLatestEthUsdPrice(), 100000000000);
    });
    //#endregion
    
    //#region Test buy function
    it('Buy tokens, Test 1', async () => {
        const stage = 2;

        // transfer 1M tokens to vesting contract
        await pmo.transfer(vestingContract.address, BigInt(1000000 * 10 ** 18));
        
        // check if stage 2 is not open, open it
        await vestingContract.setStageOpen(stage);

        // mock the ETH price to $1800(1 ETH = 1800 USDT)
        await vestingContract.setLatestEthUsdPrice(1800.00 * 10 ** 8);

        // buy 1 ETH worth of tokens
        await vestingContract.buy(stage, {from: testAccount1, value: 1 * 10 ** 18});

        // in stage 2, 1 token = 0.18 USDT, so 1 ETH = 1800 USDT, so 1800 / 0.18 = 10000 tokens
        // immadiage token transfer is 8% of 10000 = 800 tokens that user will get immadiately

        // Cheking buyer's token balance
        const balance = await vestingContract.checkBalance(stage, testAccount1);

        assert.equal(balance, (10000-800) * 10 ** 18);

        // check if buyer received 800 tokens
        const buyerTokenBalance = await pmo.balanceOf(testAccount1);
        assert.equal(buyerTokenBalance, 800 * 10 ** 18);

        // get tokens available to buy
        const tokensAvailableToBuy = await vestingContract.getTokensAvailableToBuy(stage);
        assert.equal(tokensAvailableToBuy, (28000000 * 10 ** 18) - (10000 * 10 ** 18));
    });

    it('Buy tokens, Test 2', async () => {
        const stage = 3;

        // transfer 1M tokens to vesting contract
        await pmo.transfer(vestingContract.address, BigInt(1000000 * 10 ** 18));
        
        // check if stage 3 is not open, open it
        if (!await vestingContract.stageOpen(stage)) {
            await vestingContract.setStageOpen(stage);
        }

        // mock the ETH price to $2000(1 ETH = 2000 USDT)
        await vestingContract.setLatestEthUsdPrice(2000 * 10 ** 8);

        // buy 0.1234 ETH worth of tokens
        await vestingContract.buy(stage, {from: testAccount1, value: 0.1234 * 10 ** 18});

        // in stage 3, 1 token = 0.25 USDT, so 0.1234 ETH = 246.8 USDT, so 246.8 / 0.25 = 987.2 tokens
        // immadiage token transfer is 8% of 987.2 = 78.976 tokens that user will get immadiately
        const expectedTokenCount = 987.2;
        const expectedImmediateTokenCount = expectedTokenCount * 0.08;

        // Cheking buyer's token balance
        const balance = await vestingContract.checkBalance(stage, testAccount1);

        assert.equal(balance, (expectedTokenCount-expectedImmediateTokenCount) * 10 ** 18);

        // check if buyer received 800 tokens
        const buyerTokenBalance = await pmo.balanceOf(testAccount1);
        assert.equal(buyerTokenBalance, expectedImmediateTokenCount * 10 ** 18);

        // get tokens available to buy
        const tokensAvailableToBuy = await vestingContract.getTokensAvailableToBuy(stage);
        // write to colsone
        assert.equal(tokensAvailableToBuy, (7000000-expectedTokenCount) * 10 ** 18);
    });

    it('Buy tokens, Withrawal ETH', async () => {
        const stage = 3;

        const owner = (await web3.eth.getAccounts())[0];
        const ownerEthBalanceBeforeBuy = await web3.eth.getBalance(owner);

        // transfer 1M tokens to vesting contract
        await pmo.transfer(vestingContract.address, BigInt(1000000 * 10 ** 18));
        
        // Open the stage
        await vestingContract.setStageOpen(stage);

        // mock the ETH price to $2000(1 ETH = 2000 USDT)
        await vestingContract.setLatestEthUsdPrice(2000 * 10 ** 8);

        // buy 12 ETH worth of tokens
        await vestingContract.buy(stage, {from: testAccount1, value: 12 * 10 ** 18});

        // in stage 3, 1 token = 0.25 USDT, 2000 * 12 = 24000 USDT, so 24000 / 0.25 = 96000 tokens
        // immadiage token transfer is 8% of 96000 = 7680 tokens that user will get immadiately
        const expectedTokenCount = 96000;
        const expectedImmediateTokenCount = expectedTokenCount * 0.08;

        // Cheking buyer's token balance
        const balance = await vestingContract.checkBalance(stage, testAccount1);

        assert.equal(balance, (expectedTokenCount-expectedImmediateTokenCount) * 10 ** 18);

        // check if buyer received 7680 tokens
        const buyerTokenBalance = await pmo.balanceOf(testAccount1);
        assert.equal(buyerTokenBalance, expectedImmediateTokenCount * 10 ** 18);

        // get tokens available to buy
        const tokensAvailableToBuy = await vestingContract.getTokensAvailableToBuy(stage);
        assert.equal(tokensAvailableToBuy, (7000000-expectedTokenCount) * 10 ** 18);

        const ethBalance = await vestingContract.getEthBalance();

        // withdraw ETH
        await vestingContract.withdrawEth(ethBalance);

        // check owner's ETH balance
        const ownerEthBalanceAfterBuy = await web3.eth.getBalance(owner);
        
        assert.equal(ownerEthBalanceAfterBuy - ownerEthBalanceBeforeBuy >= 11.999 * 10 ** 18, true);
    });

    

    //#endregion
});