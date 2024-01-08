//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IYoloDice {
    /// @notice IERC721, returns owner of token.
    function ownerOf(uint256 tokenId) external view returns (address);
    /// @notice IERC721, returns number of tokens owned.
    function balanceOf(address owner) external view returns (uint256);
    /// @notice IERC721, returns total number of tokens created.
    function totalSupply() external view returns (uint256);
    /// @notice IERC721Enumerable, returns token ID.
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

interface IYoloChips {
    /// @notice IERC20, returns number of tokens owned.
    function balanceOf(address account) external view returns (uint256);
    /// @notice Burns chips from whitelisted contracts.
    function spend(address account, uint256 amount) external;
    /// @notice Performs accounting before properties are transferred.
    function updateOwnership(address _from, address _to) external;
}

interface IYoloBoardDeed {
    /// @notice IERC721, returns number of tokens owned.
    function balanceOf(address owner) external view returns (uint256);
    /// @notice IERC721Enumerable, returns token ID.
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    /// @notice Returns yield of the given token.
    function yieldRate(uint256 tokenId) external view returns (uint256);
}
