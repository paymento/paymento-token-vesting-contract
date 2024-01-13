const vesting = artifacts.require('MockedVesting');
const helper = require("../helpers/truffleTestHelper");

// test deploy
contract('MockedVesting', async () => {
    
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

    //#region Check Whitelist function
    // function addToWhiteList should only work for stage 2 & 3
    it('addToWhitelist should only work for stage 2 & 3', async () => {
        try {
            await vestingContract.addToWhitelist(0, '0x077D360f11D220E4d5D831430c81C26c9be7C4A4');
            assert.fail();
        } catch (error) {
            assert.ok(/revert/.test(error.message));
        }
    });

    // function removeFromWhiteList should only work for stage 2 & 3
    it('removeFromWhitelist should only work for stage 2 & 3', async () => {
        try {
            await vestingContract.removeFromWhitelist(0, '0x077D360f11D220E4d5D831430c81C26c9be7C4A4');
            assert.fail();
        } catch (error) {
            assert.ok(/revert/.test(error.message));
        }
    });

    // Check address whitelist
    it('Check whitelist function', async () => {
        // check if address is NOT whitelisted
        assert.equal(await vestingContract.whitelistedAddresses(2, '0x077D360f11D220E4d5D831430c81C26c9be7C4A4'), false);

        // add address to whitelist
        await vestingContract.addToWhitelist(2, '0x077D360f11D220E4d5D831430c81C26c9be7C4A4');

        // check again if address is whitelisted
        assert.equal(await vestingContract.whitelistedAddresses(2, '0x077D360f11D220E4d5D831430c81C26c9be7C4A4'), true);
    });

    // function addToWhitelist should fail if not called by owner
    it('Check addToWhitelist function calling by not owner', async () => {
        try {
            await vestingContract.addToWhitelist(2, '0x077D360f11D220E4d5D831430c81C26c9be7C4A4', {from: '0x077D360f11D220E4d5D831430c81C26c9be7C4A4'});
            assert.fail();
        } catch (error) {
            assert.ok(/revert/.test(error.message));
        }
    });

    // function removeFromWhitelist should fail if not called by owner
    it('Check removeFromWhitelist function calling by not owner', async () => {
        try {
            await vestingContract.removeFromWhitelist(2, '0x077D360f11D220E4d5D831430c81C26c9be7C4A4', {from: '0x077D360f11D220E4d5D831430c81C26c9be7C4A4'});
            assert.fail();
        } catch (error) {
            assert.ok(/revert/.test(error.message));
        }
    });

    // Check if address is whitelisted
    it('Check if address is whitelisted', async () => {
        assert.equal(await vestingContract.whitelistedAddresses(2, '0x077D360f11D220E4d5D831430c81C26c9be7C4A4'), true);
    });

    // whitelistedAddresses can be called by anyone
    it('whitelistedAddresses can be called by anyone', async () => {
        assert.equal(await vestingContract.whitelistedAddresses(2, '0x077D360f11D220E4d5D831430c81C26c9be7C4A4', {from: '0x077D360f11D220E4d5D831430c81C26c9be7C4A4'}), true);
    });

    // Check removeFromWhitelist function
    it('Check removeFromWhitelist function', async () => {
        await vestingContract.removeFromWhitelist(2, '0x077D360f11D220E4d5D831430c81C26c9be7C4A4');

        assert.equal(await vestingContract.whitelistedAddresses(2, '0x077D360f11D220E4d5D831430c81C26c9be7C4A4'), false);
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
    
});