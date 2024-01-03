// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @notice Get a Series based collection's supply metadata
 * @author highlight.xyz
 */
interface IERC721GeneralSupplyMetadata {
    /**
     * @notice Get a series based collection's supply, burned tokens notwithstanding
     */
    function supply() external view returns (uint256);

    /**
     * @notice Get a series based collection's total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Get a series based collection's supply cap
     */
    function limitSupply() external view returns (uint256);
}
