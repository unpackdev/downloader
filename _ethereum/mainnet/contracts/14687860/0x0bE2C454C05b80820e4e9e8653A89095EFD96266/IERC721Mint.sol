// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow mminting
interface IERC721Mint {

    /// @notice event emitted when tokens are minted
    event Minted(
        address target,
        uint256 id
    );

    /// @notice mint tokens of specified amount to the specified address
    /// @param id the amount to mint
    function mint(
        uint256 id
    ) external returns (uint256 tokenId);

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param id the amount to mint
    function mintTo(
        address recipient,
        uint256 id
    ) external returns (uint256 tokenId);

}
