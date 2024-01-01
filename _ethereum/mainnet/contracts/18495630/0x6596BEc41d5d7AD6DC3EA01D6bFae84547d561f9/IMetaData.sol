// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Registrar.sol";

/// @title IMetaData interface
/// @notice The metadata of NFT addresses is fully generated on-chain, including the SVG image.
/// @dev The metadata logic is encapsulated here so it can be easier to update without doing
/// a full upgrade of the Registrar.
interface IMetaData {
  /// @notice Returns the URI for an NFT address
  /// @param tokenId ID of the NFT address
  /// @param registrar Registrar
  function getTokenURI(uint256 tokenId, Registrar registrar) external view returns (string memory);

  /// @notice Returns the SVG image for an NFT address
  /// @param tokenId ID of the NFT address
  /// @param registrar Registrar
  function getImage(uint256 tokenId, Registrar registrar) external view returns (string memory);

  /// @notice Returns the metadata for and NFT address
  /// @param tokenId ID of the NFT address
  /// @param registrar Registrar
  function getMetaData(uint256 tokenId, Registrar registrar) external view returns (string memory);
}
