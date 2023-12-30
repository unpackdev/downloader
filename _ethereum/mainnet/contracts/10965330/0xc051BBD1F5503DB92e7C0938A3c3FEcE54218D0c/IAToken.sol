// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface IAToken {
    function transfer(address dst, uint256 amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);
}
