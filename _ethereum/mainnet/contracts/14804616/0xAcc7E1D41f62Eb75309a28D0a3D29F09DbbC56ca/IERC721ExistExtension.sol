// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

/// @title ERC721 extension with exist function public
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
interface IERC721ExistExtension {
    /* ========== VIEWS ========== */
    /// @notice Verify a specific token id exist
    /// @param tokenId token id
    /// @return true for existing token, false otw
    function exists(uint256 tokenId) external view returns (bool);

    /// @notice Check ownership eventually skipping expire check
    /// @param tokenId token id
    /// @param skipExpirationCheck when true, return current owner skipping expire check
    /// @return owner address
    function ownerOf(uint256 tokenId, bool skipExpirationCheck)
        external
        view
        returns (address);
}
