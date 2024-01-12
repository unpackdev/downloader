// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IStakeFor {
    function depositFor(address user, uint256 amount) external returns (bool);
}
