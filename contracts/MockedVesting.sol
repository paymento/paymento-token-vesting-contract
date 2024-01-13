// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Vesting.sol";

contract MockedVesting is VestingContract {
    uint256 private _mockedEthUsdPrice = 200000000000; // Assuming the ETH/USDT is $2000
    constructor(IERC20 _token, AggregatorV3Interface _ethUsdPriceFeed) VestingContract(_token, _ethUsdPriceFeed){
        
    }

    function getLatestEthUsdPrice() public override view returns (uint256) {
        return _mockedEthUsdPrice;
    }

    function setLatestEthUsdPrice(uint256 price) public onlyOwner(){
        _mockedEthUsdPrice = price;
    }
}