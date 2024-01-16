// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow mminting
interface IERC1155Mint {

    /// @notice event emitted when tokens are minted
    event ERC1155TokenMinted(
        address minter,
        uint256 id,
        uint256 quantity
    );

    /// @notice mint tokens of specified amount to the specified address
    /// @param quantity the amount to mint
    function mint(
        uint256 id,
        uint256 quantity,
        bytes memory data
    ) external;

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param quantity the amount to mint
    function mintTo(
        address recipient,
        uint256 id,
        uint256 quantity,
        bytes memory data
    ) external;

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param quantities the quantity to mint
    /// @param data transfer bytes data
    function batchMintTo(
        address recipient,
        uint256[] memory ids,
        uint256[] calldata quantities,
        bytes memory data
    ) external;
}
