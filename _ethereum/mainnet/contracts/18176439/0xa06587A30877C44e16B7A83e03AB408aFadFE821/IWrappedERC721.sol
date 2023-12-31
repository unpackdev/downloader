// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";

/// @title An interface for a custom ERC721 contract used in the bridge
interface IWrappedERC721 is IERC721Metadata {

    /// @notice Returns the name of the token
    /// @return The name of the token
    function name() external view returns(string memory);

    /// @notice Returns the symbol of the token
    /// @return The symbol of the token
    function symbol() external view returns(string memory);

    /// @notice Returns the address of the bridge contract
    /// @return The address of the bridge contract
    function bridge() external view returns(address);

    /// @notice Creates tokens and assigns them to account
    /// @param to The receiver of tokens
    /// @param tokenId The ID of minted token
    function mint(address to, uint256 tokenId) external;

    /// @notice Destroys a token with a given ID
    /// @param tokenId The ID of the token to destroy
    function burn(uint256 tokenId) external;

    /// @notice Is emitted on every mint of the token
    event Mint(address indexed to, uint256 indexed tokenId);
    
    /// @notice Is emitted on every burn of the token
    event Burn(uint indexed tokenId);
}

