//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

interface ITerraforms {
    function tokenSVG(uint tokenid) external view returns (string memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract TerraformLogoElement is Ownable {
  ITerraforms terraforms = ITerraforms(0x4E1f41613c9084FdB9E34E11fAE9412427480e56);
  address public sourceContract = address(0x4E1f41613c9084FdB9E34E11fAE9412427480e56);

  string public siteUrl = 'https://mathcastles.xyz/';
  string public collectionUrl = 'https://opensea.io/collection/terraforms';
  string public twitterUrl;
  string public discordUrl = 'https://discord.gg/QBJ5zRSt';

  constructor() Ownable() {}

  /// @notice Sets the website for the collection
  function setSiteUrl(string memory url) external onlyOwner {
    siteUrl = url;
  }

  /// @notice Sets the collection url such as OpenSea
  function setCollectionUrl(string memory url) external onlyOwner {
    collectionUrl = url;
  }

  /// @notice Sets the discord url
  function setTwitterUrl(string memory url) external onlyOwner {
    twitterUrl = url;
  }

  /// @notice Sets the discord url
  function setDiscordUrl(string memory url) external onlyOwner {
    collectionUrl = url;
  }

  /// @notice Specifies whether or not non-owners can use a token for their logo layer
  /// @dev Required for any element used for a logo layer
  function mustBeOwnerForLogo() external view returns (bool) {
    return true;
  }

  /// @notice Returns the owner of a terraform token
  /// @dev To set a terraform token as a logo layer, sender must own terraform
  function ownerOf(uint256 tokenId) external view returns (address) {
    return terraforms.ownerOf(tokenId);
  }

  function balanceOf(address owner) public view returns (uint256) {
    return terraforms.balanceOf(owner);
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
    return terraforms.tokenOfOwnerByIndex(owner, index);
  }

  /// @notice Gets the SVG for the logo layer
  /// @dev Required for any element used for a logo layer
  /// @param tokenId, the tokenId that SVG will be fetched for
  function getSvg(uint256 tokenId) public view returns (string memory) {
    return terraforms.tokenSVG(tokenId);
  }
}