// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

/// @title Crypto Bear Watch Club Pieces Interface
/// @author Kfish n Chips
/// @notice Interface of CBWC contract
/// @custom:security-contact security@kfishnchips.com
interface ICBWC {
     /// @notice returns the owner of the `tokenId_` token.
     /// @dev `tokenId_` must exist.
     /// @param tokenId_ the id token
     /// @return Returns the owner´s address of the `tokenId` token.
    function ownerOf(uint256 tokenId_) external view returns (address);
}
