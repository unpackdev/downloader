// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

/// @title DentistCoin ERC20 contract
contract DentistCoin is ERC20, ERC20Burnable {
    /// @notice Contract constructor which initializes on ERC20 core implementation and mints 8.21 billion tokens to deployer
    constructor() ERC20("DentistCoin", "DEN") {
        _mint(msg.sender, 8210000000 * 10**decimals());
    }
}
