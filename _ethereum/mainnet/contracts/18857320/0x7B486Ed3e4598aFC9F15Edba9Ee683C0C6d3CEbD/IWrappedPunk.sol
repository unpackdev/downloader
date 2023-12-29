// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.20;

/// @notice Wrapped punk interface. Methods copied from etherscan.
interface IWrappedPunk {
    /// @notice Users need to register a proxy to mint wrappedpunks.
    function registerProxy() external;

    /// @notice Get proxy info for a given address.
    /// @param user The address of the user.
    /// @return The address of the proxy.
    function proxyInfo(address user) external view returns (address);

    /// @notice After sending a punk to the proxy, users need to mint the wrapped punk.
    /// @param punkIndex The index of the punk to mint.
    function mint(uint256 punkIndex) external;

    /// @notice Burn the wrapped punk and get the unwrapped punk.
    function burn(uint256 punkIndex) external;

    /// @notice It implements the ERC721 interface.
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @notice It implements the ERC721 interface.
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /// @notice It implements the ERC721 interface.
    function ownerOf(uint256 tokenId) external view returns (address);
}
