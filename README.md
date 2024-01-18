# Project Title

Paymento is an innovative TRUE non-custodial crypto payment platform that seamlessly integrates Crypto Payment Gateway, Buy Now, Pay Later (BNPL) services using DeFi lending and borrowing protocols

## Overview

Welcome to the Paymento Vesting Contract! This smart contract manages the allocation and vesting of tokens across different stages of our project. Whether you are an investor or a developer, this README provides essential information on how the contract works and how you can interact with it.

## Table of Contents

- [Paymento](#project-title)
  - [Overview](#overview)
  - [Table of Contents](#table-of-contents)
  - [Smart Contract Details](#smart-contract-details)
    - [Stages](#stages)
    - [VestingStageModel Struct](#vestingstagemodel-struct)
    - [Variables and Mappings](#variables-and-mappings)
    - [Constructor](#constructor)
    - [Functions](#functions)
  - [Getting Started](#getting-started)
    - [Requirements](#requirements)
    - [Installation](#installation)
    - [Tests](#tests)
  - [Usage](#usage)
    - [Investors](#investors)
    - [Developers](#developers)
  - [Contributing](#contributing)
  - [License](#license)

## Smart Contract Details

### Stages

The contract defines the following stages:

1. **Early Investors**
2. **Seed**
3. **Private Sale 1**
4. **Private Sale 2**
5. **Community**
6. **Partnership**
7. **Advisors**
8. **Development and Team**
9. **Geo Expansion Reserves**

Each stage has its token allocation, price, and vesting parameters.

### VestingStageModel Struct

The `VestingStageModel` struct holds data for each vesting stage, including:

- `tokenCount`: Total number of tokens to be vested.
- `price`: Token price.
- `immediateTokenReleasePercentage`: Percentage of tokens released immediately.
- `vestingDays`: Vesting duration in days.

### Variables and Mappings

The contract uses various variables and mappings to track token allocations, user balances, whitelists, and more.

### Constructor

The constructor initializes the contract with the ERC-20 token and Chainlink ETH/USD price feed. It also sets up the parameters for each vesting stage.

### Functions

The contract provides functions for the owner to manage stages, whitelists, and allocations. Users can buy tokens, claim vested tokens, and check balances.

## Getting Started

### Requirements

- [Node.js](https://nodejs.org/)
- [Truffle](https://www.trufflesuite.com/truffle)

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/paymento/paymento-token-vesting-contract.git
   cd project-name
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Deploy the contract:

   ```bash
   truffle migrate
   ```

### Tests

1. Start Ganache:
   
   Make sure Ganache is running. Ganache is a personal blockchain that Truffle can use for testing. If you haven't installed Ganache, you can download it from the [official website](https://www.trufflesuite.com/ganache) and follow the installation instructions.

2. Configure Truffle:

   Ensure that your Truffle configuration (`truffle-config.js` or `truffle.js`) is set up to use Ganache. It should look something like this:

   ```javascript
   module.exports = {
     networks: {
       development: {
         host: "127.0.0.1",
         port: 7545, // Ganache default port
         network_id: "*" // Match any network id
       }
     },
   };
   ```

   Make sure the `host` and `port` values match your Ganache configuration.

3. Run Tests:

   Open a terminal and navigate to the root directory of your Truffle project. Run the following command to execute your tests:

   ```bash
   truffle test
   ```

   Truffle will look for test files in the `test` directory and execute them on the Ganache blockchain. Ensure that your smart contract migrations are complete, and the contract is deployed on the local Ganache blockchain.

4. Review Test Output:

   Truffle will display the test results in the terminal. It will indicate whether each test case passed or failed. If any tests fail, review the error messages to identify and fix the issues in your smart contract or test cases.

## Usage

### Investors

If you are an investor looking to participate in the token sale, follow these steps:

1. Review the vesting stages and token prices in the contract.
2. During the specified stages, use the `buy` function to purchase tokens.
3. If applicable, ensure you are whitelisted for Private Sale 1 or Private Sale 2.
4. Monitor your vested tokens and claim them using the `claimTokens` function.

### Developers

If you are a developer interested in integrating or contributing to the project, consider the following:

- Familiarize yourself with the contract's functions and variables.
- Understand the vesting logic and how it affects users.
- Review and adhere to the contract's ownership and access control mechanisms.

## Contributing

We welcome contributions! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE). Feel free to use, modify, and distribute the code. See the [LICENSE](LICENSE) file for details.
