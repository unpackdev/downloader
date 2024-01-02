// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface FeeControllerI {
    function getMintFee(address collection, uint256 price, uint256 quantity) external view returns (uint256);

    function getFeePayoutAddress() external view returns (address);
}