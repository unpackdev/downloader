// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PudgySerumsInterface {
    function consumeSerum(uint _serumType, address _account) external {}
    function balanceOf(address account, uint256 id) external view returns (uint256) {}
}