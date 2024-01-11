// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Vesting.sol";

contract MockedVesting is VestingContract {
    int256 private _mockedEthUsdPrice = 0;
    constructor(IERC20 _token, AggregatorV3Interface _ethUsdPriceFeed) VestingContract(_token, _ethUsdPriceFeed){
        
    }

    function getLatestEthUsdPrice() public view returns (uint256) {
        return _mockedEthUsdPrice;
    }

    function setLatestEthUsdPrice(uint256 price) onlyOwner(){
        _mockedEthUsdPrice = price;
    }
}