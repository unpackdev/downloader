// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IChickenNoodle.sol";

interface IFarm {
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    struct PagingData {
        address tokenOwner;
        uint16 limit;
        uint16 page;
    }

    function totalChickenStaked() external view returns (uint16);

    function MINIMUM_TO_EXIT() external view returns (uint256);

    function MAX_TIER_SCORE() external view returns (uint8);

    function MAXIMUM_GLOBAL_EGG() external view returns (uint256);

    function DAILY_GEN0_EGG_RATE() external view returns (uint256);

    function DAILY_GEN1_EGG_RATE() external view returns (uint256);

    function eggPerTierScore() external view returns (uint256);

    function totalEggEarned() external view returns (uint256);

    function lastClaimTimestamp() external view returns (uint256);

    function denIndices(uint16 tokenId) external view returns (uint16);

    function chickenNoodle() external view returns (IChickenNoodle);

    function isChicken(uint16 tokenId) external view returns (bool);

    function tierScoreForNoodle(uint16 tokenId) external view returns (uint8);

    function randomNoodleOwner(uint256 seed) external view returns (address);
}
