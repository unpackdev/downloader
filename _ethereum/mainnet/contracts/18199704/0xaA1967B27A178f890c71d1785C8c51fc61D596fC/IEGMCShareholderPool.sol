// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEGMCShareholderPool {
    function depositFor(address user, uint amount) external;
}