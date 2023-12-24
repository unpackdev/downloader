// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IYespXStakeVerifier {
    enum DiscountTier {
        NO_TIER,
        TIER_1,
        TIER_2,
        TIER_3
    }

    function discountThresholds(
        DiscountTier tier
    ) external view returns (uint256);

    function amountStaked(address user) external view returns (uint256);

    function firstStakedTimestamp(address user) external view returns (uint256);

    function stakeModifiedTimestamp(
        address user
    ) external view returns (uint256);

    function isUserDiscountElegible(address user) external view returns (bool);

    function userDiscountTier(
        address user
    ) external view returns (DiscountTier);

    function setSourceAddress(string calldata sourceAddress_) external;

    function executeFromSameChain(bytes calldata payload_) external;
}
