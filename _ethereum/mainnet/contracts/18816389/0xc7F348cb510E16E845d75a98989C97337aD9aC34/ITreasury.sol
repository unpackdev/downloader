// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ITreasury {
    function withdraw(uint256 tokenAmount) external;

    function withdrawTo(address _to, uint256 _amount) external;
}