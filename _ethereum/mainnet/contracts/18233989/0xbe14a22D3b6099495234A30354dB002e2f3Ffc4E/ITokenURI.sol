// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ITokenURI {
    /**
     * @dev Returns the metadata URI for a given token ID
     *
     * @param tokenId The id of the token
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
