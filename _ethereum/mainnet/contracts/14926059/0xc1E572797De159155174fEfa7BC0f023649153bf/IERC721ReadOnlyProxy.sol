// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

/// @title ERC721 Proxy Interface
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
/// @notice O/W token interface used by Rentable main contract
interface IERC721ReadOnlyProxy {
    /* ========== VIEWS ========== */

    /// @notice Get wrapped token address
    /// @return wrapped token address
    function getWrapped() external view returns (address);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Mint a token
    /// @param to receiver
    /// @param tokenId token id
    function mint(address to, uint256 tokenId) external;

    /// @notice Burn a token
    /// @param tokenId token id
    function burn(uint256 tokenId) external;
}
