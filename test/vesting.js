const vesting = artifacts.require('VestingContract');

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
        assert.equal(stage.vestingMonths, 24);
    });

    // test if stage 0 is close
    it('Check stage 0 status', async () => {
        assert.equal(await vestingContract.stageOpen(0), false);

        await vestingContract.setStageOpen(0);

        assert.equal(await vestingContract.stageOpen(0), true);
    });
});