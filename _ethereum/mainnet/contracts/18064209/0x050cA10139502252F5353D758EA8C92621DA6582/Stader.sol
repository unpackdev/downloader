// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./console.sol";
interface IStader {
    function deposit(address receipient) external payable returns(uint256);
}

contract StaderStaker {
    address constant public stader = 0xcf5EA1b38380f6aF39068375516Daf40Ed70D299;

    receive() external payable {
        IStader(stader).deposit{value: msg.value}(msg.sender);
    }
}
