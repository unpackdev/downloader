// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow mminting
interface IERC20Mint {

    /// @notice event emitted when tokens are minted
    event Minted(
        address target,
        uint256 amount
    );

    /// @notice mint tokens of specified amount to the specified address
    /// @param amount the amount to mint
    function mint(
        uint256 amount
    ) external;

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param amount the amount to mint
    function mintTo(
        address recipient,
        uint256 amount
    ) external;

    function setMintAllowance(address receiver, uint256 tokenId, uint256 amount) external;

}
