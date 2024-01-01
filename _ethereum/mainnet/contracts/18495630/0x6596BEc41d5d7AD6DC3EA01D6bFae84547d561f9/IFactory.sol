// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @title IFactory interface
/// @dev Factories are used to register and deploy NFT addresses.
interface IFactory {
  /// @dev Deploys a smart contract to an NFT address
  /// @param nftAddress NFT address
  /// @param creationCode Smart contract bytecode (i.e. bytecode containing the constructor and
  /// initialization data)
  function deploy(address nftAddress, bytes memory creationCode) external;

  /// @dev Mints a new NFT address
  /// @param owner Owner of the NFT address
  /// @param salt Salt used to generate the NFT Address
  function mint(address owner, uint256 salt) external returns (address payable);
}
