// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

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
        Community,          // Stage 4: 49M tokens @ price 0USDT for Community
        Partnership,        // Stage 5: 28M tokens @ price 0USDT for Partnership
        Advisors,           // Stage 6: 10.5M tokens @ price 0USDT for Advisors
        DevelopmentAndTeam, // Stage 7: 70M tokens @ price 0USDT for DevelopmentAndTeam
        GeoExpansionReserves // Stage 8: 52.5M tokens @ price 0USDT for GeoExpansionReserves
    }

    // Struct to hold the vesting stage data
    struct VestingStageModel {
        uint256 tokenCount; // Number of tokens to be vested
        uint256 price; // Price of the token
        uint256 immadiateTokenReleasePercentage; // Percentage of tokens to be released immadiately
        uint256 vestingMonths; // Number of months for vesting
    }

    IERC20 public token;
    AggregatorV3Interface internal ethUsdPriceFeed;

    mapping(uint256 => VestingStageModel) public vestingStages;
    mapping(uint256 => mapping(address => bool)) public whitelistedAddresses;
    mapping(uint256 => uint256) public totalTokenPurchasedOrAllocatedPerStage;
    mapping(uint256 => mapping(address => uint256)) public userBalancePerStage;
    mapping(uint256 => mapping(address => uint256)) public userLastClaimTimePerStage;
    
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
            immadiateTokenReleasePercentage: 5,
            vestingMonths: 24
        });
        
        // Seed
        vestingStages[uint256(Stages.Seed)] = VestingStageModel({
            tokenCount: 24500000 * 10 ** 18,
            price: 120,
            immadiateTokenReleasePercentage: 5,
            vestingMonths: 20
        });

        // Private Sale 1
        vestingStages[uint256(Stages.PrivateSale1)] = VestingStageModel({
            tokenCount: 28000000 * 10 ** 18,
            price: 180,
            immadiateTokenReleasePercentage: 8,
            vestingMonths: 16
        });

        // Private Sale 2
        vestingStages[uint256(Stages.PrivateSale2)] = VestingStageModel({
            tokenCount: 7000000 * 10 ** 18,
            price: 250,
            immadiateTokenReleasePercentage: 8,
            vestingMonths: 12
        });
        
        // Community
        vestingStages[uint256(Stages.Community)] = VestingStageModel({
            tokenCount: 49000000 * 10 ** 18,
            price: 0,
            immadiateTokenReleasePercentage: 10,
            vestingMonths: 36
        });

        // Partnership
        vestingStages[uint256(Stages.Partnership)] = VestingStageModel({
            tokenCount: 28000000 * 10 ** 18,
            price: 0,
            immadiateTokenReleasePercentage: 10,
            vestingMonths: 36
        });

        // Advisors
        vestingStages[uint256(Stages.Advisors)] = VestingStageModel({
            tokenCount: 10500000 * 10 ** 18,
            price: 0,
            immadiateTokenReleasePercentage: 10,
            vestingMonths: 20
        });

        // Development And Team
        vestingStages[uint256(Stages.DevelopmentAndTeam)] = VestingStageModel({
            tokenCount: 70000000 * 10 ** 18,
            price: 0,
            immadiateTokenReleasePercentage: 10,
            vestingMonths: 24
        });

        // Geo Expansion Reserves
        vestingStages[uint256(Stages.GeoExpansionReserves)] = VestingStageModel({
            tokenCount: 52500000 * 10 ** 18,
            price: 0,
            immadiateTokenReleasePercentage: 10,
            vestingMonths: 60
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

        return vestingStages[stage].tokenCount - totalTokenPurchasedOrAllocatedPerStage[stage];
    }

    /**
    * @dev Users can buy the tokens from the contract
    * @dev Buy is allowed only in the stages Early Investors, Seed, Private Sale 1, Private Sale 2
    * @dev To buy the tokens, in stage Private Sale 1 and 2 the user must be whitelisted
    * @dev The amount of tokens to buy is calculated by dividing the amount of ETH/USDT sent by the price of the stage
    * @param stage uint256 The stage to buy
    */
    function buy(uint stage) external payable {
        require(stage < uint256(Stages.Community), "Invalid stage to buy");

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
        require(totalTokenPurchasedOrAllocatedPerStage[stage] + tokensToBuy <= vestingStages[stage].tokenCount, "Not enough tokens available");

        // Transfer the immadiate percentage of tokens to the user
        uint256 immadiateTokenRelease = (tokensToBuy * vestingStages[stage].immadiateTokenReleasePercentage) / 100;
        
        // Update the total tokens purchased
        totalTokenPurchasedOrAllocatedPerStage[stage] += tokensToBuy;

        // Update user balance
        userBalancePerStage[stage][msg.sender] += tokensToBuy - immadiateTokenRelease;

        // Update user purchase time if it is the first purchase
        if(userLastClaimTimePerStage[stage][msg.sender] == 0) {
            userLastClaimTimePerStage[stage][msg.sender] = block.timestamp;
        }

        token.transfer(msg.sender, immadiateTokenRelease);
    }

    /**
    * @dev Allocate tokens to a user
    * @param stage uint256 The stage to allocate the tokens
    * @param user address The address to allocate the tokens
    * @param amount uint256 The amount of tokens to allocate
    */
    function allocateTokens(uint stage, address user, uint256 amount) external onlyOwner {
        // Check if stage can be allocated
        require(stage > uint256(Stages.PrivateSale2) && stage < uint256(Stages.GeoExpansionReserves), "Invalid stage");

        require(amount <= getTokensAvailableToBuy(stage), "Not enough tokens available");

        totalTokenPurchasedOrAllocatedPerStage[stage] += amount;

        // Transfer the immadiate percentage of tokens to the user
        uint256 immadiateTokenRelease = 0;

        if(vestingStages[stage].immadiateTokenReleasePercentage > 0) {
            immadiateTokenRelease = (amount * vestingStages[stage].immadiateTokenReleasePercentage) / 100;
            token.transfer(user, immadiateTokenRelease);
        }

        // Update user balance
        userBalancePerStage[stage][user] += amount - immadiateTokenRelease;

        // Update user purchase time
        userLastClaimTimePerStage[stage][user] = block.timestamp;
    }

    /**
    * @dev Claim tokens for a stage
    * @param stage uint256 The stage to claim the tokens
    */
    function claimTokens(uint stage) external {
        require(stage < uint256(Stages.GeoExpansionReserves), "Invalid stage");

        // check if user has balance
        require(userBalancePerStage[stage][msg.sender] > 0, "User has no balance");

        // calculate days since last claim
        uint256 daysSinceLastClaim = (block.timestamp - userLastClaimTimePerStage[stage][msg.sender]) / 86400;

        // Check if at least 1 day has passed since last claim
        require(daysSinceLastClaim > 0, "At least 1 day must pass since last claim");

        // Calculate the number of tokens to release
        if(daysSinceLastClaim >= vestingStages[stage].vestingMonths * 30) {
            // If all the vesting period has passed then release all the tokens
            userBalancePerStage[stage][msg.sender] = 0;
            token.transfer(msg.sender, userBalancePerStage[stage][msg.sender]);
            return;
        }

        // For example if the user has balance of 1000 tokens in Private Sale 1 and 10 days has passed since last claim
        // Then the user can claim 1000 * 10 / (16 * 30) = 20 tokens
        uint256 tokensToRelease = (userBalancePerStage[stage][msg.sender] * daysSinceLastClaim) / (vestingStages[stage].vestingMonths * 30);

        // Update user balance
        userBalancePerStage[stage][msg.sender] -= tokensToRelease;

        // Update user last claim time
        userLastClaimTimePerStage[stage][msg.sender] = block.timestamp;

        // Transfer the tokens to the user
        token.transfer(msg.sender, tokensToRelease);
    }

    /**
    * @dev Check user balance for a stage
    * @param stage uint256 The stage to check the balance
    * @param user address The address to check the balance
    */
    function checkBalance(uint stage, address user) external view returns (uint256) {
        require(stage < uint256(Stages.GeoExpansionReserves), "Invalid stage");

        return userBalancePerStage[stage][user];
    }

    
    modifier onlyTokenContract() {
        require(msg.sender == owner(), "Caller is not the owner");
        _;
    }

}