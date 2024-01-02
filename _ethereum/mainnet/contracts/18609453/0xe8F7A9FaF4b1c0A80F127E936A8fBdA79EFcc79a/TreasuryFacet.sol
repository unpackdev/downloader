// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./LibDiamond.sol";

contract TreasuryFacet {
    event Deposit(address indexed sender, uint256 amount);

    function deposit() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}
