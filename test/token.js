// deploy the Paymento token contract
const token = artifacts.require('Paymento');
// test deploy
contract('Paymento', () => {
    it('should deploy smart contract properly', async () => {
        const tokenContract = await token.new();
        console.log(tokenContract.address);
        assert(tokenContract.address !== '');
    });
});