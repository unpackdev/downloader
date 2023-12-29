// contracts/GunsNRoses.sol
// SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;

import "./ERC20.sol";

contract DecentralizedCryptoReit is ERC20 {
    constructor(uint256 initialSupply) ERC20("Decentralized Crypto Reit", "REIT") {
        _mint(msg.sender, initialSupply);
    }
}