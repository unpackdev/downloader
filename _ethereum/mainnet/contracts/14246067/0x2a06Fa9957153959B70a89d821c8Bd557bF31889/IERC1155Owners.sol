// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow mminting
interface IERC1155Owners {

    /// @notice returns the owners of the token
    /// @param tokenId the token id
    /// @param owners the owner addresses of the token id
    function ownersOf(uint256 tokenId) external view returns (address[] memory owners);

    /// @notice returns whether given address owns given id
    /// @param tokenId the token id
    /// @param toCheck the address to check
    /// @param isOwner whether the given address is owner of the token id
    function isOwnedBy(uint256 tokenId, address toCheck) external view returns (bool isOwner);

}
