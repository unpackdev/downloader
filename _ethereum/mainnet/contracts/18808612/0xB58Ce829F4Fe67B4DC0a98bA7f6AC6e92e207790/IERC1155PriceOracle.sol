// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPriceOracleGetter
 *
 * @notice Interface for the ERC1155 asset price oracle
 */
interface IERC1155PriceOracle {
    function getAssetPrice(uint256 tokenId) external view returns (uint256);
}
