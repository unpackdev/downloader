// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

/// @title SalonCoin ERC20 contract
contract SalonCoin is ERC20, ERC20Burnable {
    /// @notice Contract constructor which initializes on ERC20 core implementation and mints 52.1 billion tokens to deployer
    constructor() ERC20("SalonCoin", "SALON") {
        _mint(msg.sender, 52100000000 * 10**decimals());
    }
}
