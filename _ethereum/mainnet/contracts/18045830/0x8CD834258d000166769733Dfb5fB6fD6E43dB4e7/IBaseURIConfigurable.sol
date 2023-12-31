// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title IBaseURIConfigurable
 * @author @NFTCulture
 * @dev Interface to define Base URI configuration functions.
 *
 * Supported Contract Specs:
 *  - ERC721A Static
 *  - ERC721A Expandable
 *  - ERC1155
 */
interface IBaseURIConfigurable {
    /*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°\
    |                   API - General Functions                   |
    \____________________________________________________________*/

    // Set URI at the contract level. ERC721 - Base URI. ERC1155 - Uri.
    function setContractURI(string memory) external;

    // Get URI configured at the contract level. ERC721 - Base URI. ERC1155 - Uri.
    function getContractURI() external view returns (string memory);
}
