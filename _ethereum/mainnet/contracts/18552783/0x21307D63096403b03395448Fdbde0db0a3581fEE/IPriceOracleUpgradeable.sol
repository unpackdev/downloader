// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPriceOracleUpgradeable {
    /**
     * @notice Get latest price normalized to 1e18 for asset
     */
    function getPrice(address asset) external view returns (uint256);

    function getUnderlyingPriceETH() external view returns (uint);

    function getWaterPrice() external view returns (uint256);
}
