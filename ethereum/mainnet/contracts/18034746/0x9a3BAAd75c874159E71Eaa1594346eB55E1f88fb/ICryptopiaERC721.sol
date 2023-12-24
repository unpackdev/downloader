// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title ICryptopiaERC721
/// @dev Non-fungible token (ERC721) 
/// @author HFB - <frank@cryptopia.com>
interface ICryptopiaERC721 {

    /// @dev Returns whether `_spender` is allowed to manage `_tokenId`
    /// @param spender Account to check
    /// @param tokenId Token id to check
    /// @return true if `spender` is allowed ot manage `_tokenId`
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
}