// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title INonFungibleTokenQueryable
 * @author @NFTCulture
 * @dev Interface to define data-retrieval functions for a NonFungible Token contract.
 */
interface INonFungibleTokenQueryable {
    /*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°\
    |                   API - General Functions                   |
    \____________________________________________________________*/

    // Return the maximum possible number of tokens that can be minted by this contract.
    function maxSupply() external view returns (uint256);

    // Return the current number of tokens that exist.
    function totalTokensExist() external view returns (uint256);

    // Return the balance owned by an address.
    function balanceOwnedBy(address) external view returns (uint256);
}
