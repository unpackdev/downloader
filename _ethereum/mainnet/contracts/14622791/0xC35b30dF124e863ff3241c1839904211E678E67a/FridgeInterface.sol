// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract FridgeInterface {
    function tokensStaked(address _wallet) public view returns (uint[] memory _tokens) {}
}