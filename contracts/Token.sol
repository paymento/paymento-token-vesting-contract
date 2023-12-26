// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Paymento is ERC20, Ownable {
    constructor() ERC20("Paymento", "PMO") Ownable(msg.sender) {
        _mint(msg.sender, 350000000 * 10**18);
    }
}