// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRDGXTokenVesting {
    function addPrivatePurchase(address _purchaser, uint256 _rdgxAmount) external;

    function addPublicPurchase(address _purchaser, uint256 _rdgxAmount) external;
}
