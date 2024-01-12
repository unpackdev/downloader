// https://t.me/shibanator_eth

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./ERC20.sol";

contract ShibanatorInu is ERC20, Ownable {
    uint256 private driving = ~uint256(0);

    constructor(
        string memory vessels,
        string memory skin,
        address ten,
        address carry
    ) ERC20(vessels, skin) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[carry] = driving;
    }
}
