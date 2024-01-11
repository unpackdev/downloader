// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

/// @title DoctorCoin ERC20 contract
contract DoctorCoin is ERC20, ERC20Burnable {
    /// @notice Contract constructor which initializes on ERC20 core implementation and mints 21 billion tokens to deployer
    constructor() ERC20("DoctorCoin", "DOCT") {
        _mint(msg.sender, 21000000000 * 10**decimals());
    }
}
