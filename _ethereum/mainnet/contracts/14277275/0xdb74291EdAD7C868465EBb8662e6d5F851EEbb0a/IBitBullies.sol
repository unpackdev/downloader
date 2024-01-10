// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IBitBullies {
    function bulliesBalance(address _user) external view returns(uint256);
}