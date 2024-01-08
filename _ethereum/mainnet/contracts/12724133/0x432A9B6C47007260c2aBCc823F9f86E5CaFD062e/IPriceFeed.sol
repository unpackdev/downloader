// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPriceFeed {
    function howManyBMIsInDAI(uint256 daiAmount) external view returns (uint256);

    function howManyDAIsInBMI(uint256 bmiAmount) external view returns (uint256);
}
