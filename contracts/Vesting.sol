// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Token.sol";

contract VestingContract is Ownable {
    // We use the SafeMath library to prevent overflows and underflows
    using Math for uint256;

    // Stages
    enum Stages {
        EarlyInvestors,     // Stage 0: 17.5M tokens @ price 0.075USDT for Early Investors
        Seed,               // Stage 1: 24.5M tokens @ price 0.12USDT for Seed
        PrivateSale1,       // Stage 2: 28M tokens @ price 0.18USDT for Private Sale 1
        PrivateSale2,       // Stage 3: 7M tokens @ price 0.25USDT for Private Sale 2
        LaunchPad,          // Stage 4: 52.5M tokens @ price 0.38USDT for LaunchPad
        Community,          // Stage 5: 49M tokens @ price 0USDT for Community
        Partnership,        // Stage 6: 28M tokens @ price 0USDT for Partnership
        Advisors,           // Stage 7: 10.5M tokens @ price 0USDT for Advisors
        DevelopmentAndTeam, // Stage 8: 70M tokens @ price 0USDT for DevelopmentAndTeam
        GeoExpansionReserves // Stage 9: 52.5M tokens @ price 0USDT for GeoExpansionReserves
    }

    // VestingType
    enum VestingType { 
        Daily, 
        Monthly 
    }

    // Struct to hold the vesting stage data
    struct VestingStageModel {
        uint256 tokenCount; // Number of tokens to be vested
        uint256 price; // Price of the token
        uint256 unlockTGE; // Unlock time
        uint256 cliff; // Cliff time
        uint256 vestingMonths; // Number of months for vesting
        uint256 monthlyVestingPercentage; // Percentage of tokens to be vested monthly
        VestingType vestingType; // Vesting type
    }

    IERC20 public token;
    AggregatorV3Interface internal ethUsdPriceFeed;

    mapping(uint256 => VestingStageModel) public vestingStages;
    mapping(uint256 => mapping(address => bool)) public whitelistedAddresses;
    mapping(uint256 => uint256) public totalTokenPurchasedPerStage;
    mapping(uint256 => mapping(address => uint256)) public userPurchasedTokensPerStage;
    mapping(uint256 => mapping(address => uint256)) public userPurchaseTimePerStage;

    mapping(uint256 => mapping(string => uint256)) public claimedTokensPerStage;
    mapping(uint256 => uint256) public totalAllocated;
    mapping(uint256 => bool) public stageOpen;
    mapping(uint256 => bool) public stageAllocationComplete;

    constructor(IERC20 _token, AggregatorV3Interface _ethUsdPriceFeed) Ownable(msg.sender) {
        token = _token;
        ethUsdPriceFeed = _ethUsdPriceFeed;

        // EarlyInvestors
        vestingStages[uint256(Stages.EarlyInvestors)] = VestingStageModel({
            tokenCount: 17500000 * 10 ** 18,
            price: 75,
            unlockTGE: 5,
            cliff: 0,
            vestingMonths: 24,
            monthlyVestingPercentage: 138,
            vestingType: VestingType.Daily
        });

        // Seed
        vestingStages[uint256(Stages.Seed)] = VestingStageModel({
            tokenCount: 24500000 * 10 ** 18,
            price: 120,
            unlockTGE: 5,
            cliff: 0,
            vestingMonths: 20,
            monthlyVestingPercentage: 166,
            vestingType: VestingType.Daily
        });

        // Private Sale 1
        vestingStages[uint256(Stages.PrivateSale1)] = VestingStageModel({
            tokenCount: 28000000 * 10 ** 18,
            price: 180,
            unlockTGE: 8,
            cliff: 0,
            vestingMonths: 16,
            monthlyVestingPercentage: 208,
            vestingType: VestingType.Daily
        });

        // Private Sale 2
        vestingStages[uint256(Stages.PrivateSale2)] = VestingStageModel({
            tokenCount: 7000000 * 10 ** 18,
            price: 250,
            unlockTGE: 8,
            cliff: 0,
            vestingMonths: 12,
            monthlyVestingPercentage: 277,
            vestingType: VestingType.Daily
        });

        // Launch Pad
        vestingStages[uint256(Stages.LaunchPad)] = VestingStageModel({
            tokenCount: 52500000 * 10 ** 18,
            price: 380,
            unlockTGE: 13,
            cliff: 0,
            vestingMonths: 9,
            monthlyVestingPercentage: 370,
            vestingType: VestingType.Daily
        });

        // Community
        vestingStages[uint256(Stages.Community)] = VestingStageModel({
            tokenCount: 49000000 * 10 ** 18,
            price: 0,
            unlockTGE: 100,
            cliff: 0,
            vestingMonths: 0,
            monthlyVestingPercentage: 100,
            vestingType: VestingType.Daily
        });

        // Partnership
        vestingStages[uint256(Stages.Partnership)] = VestingStageModel({
            tokenCount: 28000000 * 10 ** 18,
            price: 0,
            unlockTGE: 100,
            cliff: 0,
            vestingMonths: 36,
            monthlyVestingPercentage: 92,
            vestingType: VestingType.Monthly
        });

        // Advisors
        vestingStages[uint256(Stages.Advisors)] = VestingStageModel({
            tokenCount: 10500000 * 10 ** 18,
            price: 0,
            unlockTGE: 100,
            cliff: 0,
            vestingMonths: 20,
            monthlyVestingPercentage: 100,
            vestingType: VestingType.Daily
        });

        // Development And Team
        vestingStages[uint256(Stages.DevelopmentAndTeam)] = VestingStageModel({
            tokenCount: 70000000 * 10 ** 18,
            price: 0,
            unlockTGE: 0,
            cliff: 3,
            vestingMonths: 24,
            monthlyVestingPercentage: 138,
            vestingType: VestingType.Daily
        });

        // Geo Expansion Reserves
        vestingStages[uint256(Stages.GeoExpansionReserves)] = VestingStageModel({
            tokenCount: 52500000 * 10 ** 18,
            price: 0,
            unlockTGE: 0,
            cliff: 3,
            vestingMonths: 60,
            monthlyVestingPercentage: 166,
            vestingType: VestingType.Monthly
        });
    }

    /**
    * @dev Open a stage by Owner
    * @param stage uint256 The stage to open
    */
    function setStageOpen(uint stage) external onlyOwner {
        require(stage < uint256(Stages.GeoExpansionReserves), "Invalid stage");

        stageOpen[stage] = true;
    }

    /**
    * @dev Close a stage by Owner
    * @param stage uint256 The stage to close
    */
    function setStageClose(uint stage) external onlyOwner {
        require(stage < uint256(Stages.GeoExpansionReserves), "Invalid stage");

        stageOpen[stage] = false;
    }

    /**
    * @dev Register an address in whitelist of Private Sale 1 and Private Sale 2
    * @param stage uint256 The stage to close
    * @param user address The address to register
    */
    function addToWhitelist(uint stage, address user) external onlyOwner {
        require(stage == (uint)(Stages.PrivateSale1) || stage == (uint)(Stages.PrivateSale2),
            "Only Private Sale 1 and Private Sale 2 can have a whitelist"
        );

        whitelistedAddresses[stage][user] = true;
    }

    /**
    * @dev Remove an address from whitelist of Private Sale 1 and Private Sale 2
    * @param stage uint256 The stage to close
    * @param user address The address to remove
    */
    function removeFromWhitelist(uint stage, address user) external onlyOwner {
        require(stage == (uint)(Stages.PrivateSale1) || stage == (uint)(Stages.PrivateSale2),
            "Only Private Sale 1 and Private Sale 2 can have a whitelist"
        );

        whitelistedAddresses[stage][user] = false;
    }

    /**
    * @dev Get the latest ETH/USD price from Chainlink
    * @return uint256 The latest ETH/USD price
    */
    function getLatestEthUsdPrice() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        return uint256(price);
    }

    /**
    * @dev Get the total token count for a stage
    * @param stage uint256 The stage to get the total token count
    */
    function getTotalTokenForStage(uint stage) public view returns (uint256) {
        return vestingStages[stage].tokenCount;
    }

    /**
    * @dev Get tokens available to buy for a stage
    * @param stage uint256 The stage to get the tokens available to buy
    */
    function getTokensAvailableToBuy(uint stage) public view returns (uint256) {
        require(stage < uint256(Stages.GeoExpansionReserves), "Invalid stage");

        return vestingStages[stage].tokenCount - totalTokenPurchasedPerStage[stage];
    }

    /**
    * @dev Users can buy the tokens from the contract
    * @dev To buy the tokens, in stage Private Sale 1 and 2 the user must be whitelisted
    * @dev The amount of tokens to buy is calculated by dividing the amount of ETH/USDT sent by the price of the stage
    * @param stage uint256 The stage to buy
    */
    function buy(uint stage) external payable {
        require(stage < uint256(Stages.GeoExpansionReserves), "Invalid stage");

        // Check if the stage is open
        require(stageOpen[stage], "Stage is not open");

        // Check if stage is Private Sale 1 or Private Sale 2 and if the user is whitelisted
        if(stage == (uint)(Stages.PrivateSale1) || stage == (uint)(Stages.PrivateSale2)) {
            require(whitelistedAddresses[stage][msg.sender], "User is not whitelisted");
        }

        // Get the current price of ETH/USDT
        // This api returns price in 8 decimals, for example 100000000 equals to US$1 or 228581475150 equals to US$2285.81475150
        // So we divide the price by 10 ** 5 to get the price in 3 decimals as our token price is in 3 decimals
        uint256 ethUsdPrice = getLatestEthUsdPrice() / 10 ** 5;

        // Calculate the value of ETH sent in USDT
        uint256 ethUsdValue = msg.value * ethUsdPrice;

        // Calculate the amount of tokens to buy
        uint256 tokensToBuy = (ethUsdValue / vestingStages[stage].price) * 10 ** 18;

        // Check if this amount of tokens is available to buy
        require(totalTokenPurchasedPerStage[stage] + tokensToBuy <= vestingStages[stage].tokenCount, "Not enough tokens available");

        // Update the total tokens purchased
        totalTokenPurchasedPerStage[stage] += tokensToBuy;

        // Update user balance
        userPurchasedTokensPerStage[stage][msg.sender] += tokensToBuy;

        // Update user purchase time if it is the first purchase
        if(userPurchaseTimePerStage[stage][msg.sender] == 0) {
            userPurchaseTimePerStage[stage][msg.sender] = block.timestamp;
        }
    }

    /**
    * @dev Check user balance for a stage
    * @param stage uint256 The stage to check the balance
    * @param user address The address to check the balance
    */
    function checkBalance(uint stage, address user) external view returns (uint256) {
        require(stage < uint256(Stages.GeoExpansionReserves), "Invalid stage");

        return userPurchasedTokensPerStage[stage][user];
    }

    function claimTokens(uint stage) external {
        require(stage < uint256(Stages.GeoExpansionReserves), "Invalid stage");

        // check if user has purchased tokens
        require(userPurchasedTokensPerStage[stage][msg.sender] > 0, "User has not purchased tokens");

        
    }



    modifier onlyTokenContract() {
        require(msg.sender == owner(), "Caller is not the owner");
        _;
    }

}