// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IVaultFacet.sol";

interface IDutchAuctionFacet {
    struct Storage {
        uint32 duration;
        uint256 startCoefficientX96;
        uint256 endCoefficientX96;
        uint256 startTimestamp;
        address strategy;
    }

    function checkTvlAfterRebalance(uint256 tvlBefore, uint256 tvlAfter) external returns (bool);

    function updateAuctionParams(
        uint256 startCoefficientX96,
        uint256 endCoefficientX96,
        uint32 duration,
        address strategy
    ) external;

    function auctionParams()
        external
        view
        returns (
            uint256 startCoefficientX96,
            uint256 endCoefficientX96,
            uint32 duration,
            uint256 startTimestamp,
            address strategy
        );

    function finishAuction() external;

    function startAuction() external;

    function stopAuction() external;

    function dutchAuctionInitialized() external view returns (bool);

    function dutchAuctionSelectors() external view returns (bytes4[] memory selectors_);
}
