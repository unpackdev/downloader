// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

abstract contract AvatarConstants {
    uint256 public constant MAX_SUPPLY = 3_333;
    uint256 public constant MAX_PAID_SUPPLY = 1_100;
    uint256 public constant PRICE_FULL = 0.3 ether;
    uint256 public constant PRICE_DISCOUNTED = 0.2 ether;

    uint96 internal constant INITIAL_ROYALTY_BPS = 250;
    uint96 internal constant INITIAL_MINT_AMOUNT = 300;
    uint256 internal constant THREE = 3;
    uint256 internal constant EIGHTY_FIVE = 85;
    uint256 internal constant MASK_THREE_BITS = 2**THREE - 1;
}
