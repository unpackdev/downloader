// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IMMFee {
    function getFeeInfo() external view returns (address, uint256);
}
