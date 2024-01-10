// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721Metadata Interface
 *
 * @dev Interface of the ERC721Metadata according to the EIP
 */
interface ERC721Metadata {
    /**
     * @dev ERC721 token metadata functions
     */

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}
