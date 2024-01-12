// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC1155Supply.sol";

/// @title BHSerum - BagHolderz Mutant Serum
/// @author 0xhohenheim <contact@0xhohenheim.com>
/// @notice Interface for BHSerum Multi Token contract
interface IBHSerum is IERC1155 {
    /// @notice Mint NFT
    /// @dev callable only by admin
    /// @param recipient mint to
    function mint(
        address recipient,
        uint256 tokenId,
        uint256 quantity
    ) external;

    /// @notice Fetch token URI
    /// @param tokenId token ID
    function uri(uint256 tokenId) external view returns (string memory);

    /// @notice Set URI for a token
    /// @dev callable only by admin
    /// @param tokenId token ID
    /// @param _URI URI to set for tokenId
    function setURI(uint256 tokenId, string calldata _URI) external;

    function totalSupply(uint256 id) external view returns (uint256);
}
