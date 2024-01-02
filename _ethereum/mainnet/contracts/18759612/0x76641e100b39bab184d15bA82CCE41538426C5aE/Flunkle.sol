// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";

/**
 * @title  Flunkle
 * @notice Flunkle token contract
 * @notice This contract is a gas-optimized ERC20 + EIP-2612
 */
contract Flunkle is SolmateERC20 {
    constructor() SolmateERC20("Flunkle", "FLUNKLE", 18) {
        _mint(msg.sender, 69_420_069_420);
    }
}
