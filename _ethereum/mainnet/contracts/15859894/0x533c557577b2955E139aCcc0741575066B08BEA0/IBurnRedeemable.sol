// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBurnRedeemable {
    event Redeemed(
        address indexed user,
        address indexed gfiContract,
        address indexed tokenContract,
        uint256 gfiAmount,
        uint256 tokenAmount
    );

    function onTokenBurned(address user, uint256 amount) external;
}
