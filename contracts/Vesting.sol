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
    mapping(address => mapping(string => uint256)) public claimedTokensPerStage;
    mapping(address => mapping(string => uint256)) public purchasedTokensPerStage;
    mapping(address => mapping(string => uint256)) public purchaseTimestampsPerStage;
    mapping(uint256 => uint256) public totalAllocated;
    mapping(uint256 => bool) public stageOpen;
    mapping(uint256 => bool) public stageSetOnce;
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

    function setStageOpen(uint stage) external onlyOwner {
        require(stage < uint256(Stages.GeoExpansionReserves), "Invalid stage");

        stageOpen[stage] = true;
    }

    function setStageClose(uint stage) external onlyOwner {
        require(stage < uint256(Stages.GeoExpansionReserves), "Invalid stage");

        stageOpen[stage] = false;
    }

    function addToWhitelist(uint stage, address user) external onlyOwner {
        require(stage == (uint)(Stages.PrivateSale1) || stage == (uint)(Stages.PrivateSale2),
            "Only Private Sale 1 and Private Sale 2 can have a whitelist"
        );

        whitelistedAddresses[stage][user] = true;
    }

    function removeFromWhitelist(uint stage, address user) external onlyOwner {
        require(stage == (uint)(Stages.PrivateSale1) || stage == (uint)(Stages.PrivateSale2),
            "Only Private Sale 1 and Private Sale 2 can have a whitelist"
        );

        whitelistedAddresses[stage][user] = false;
    }

    function getLatestEthUsdPrice() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        return uint256(price);
    }

    function buy(uint stage) external payable {

    }

    modifier onlyTokenContract() {
        require(msg.sender == owner(), "Caller is not the owner");
        _;
    }

}