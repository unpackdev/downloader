// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICaviar {
  /// @dev pairs[nft][baseToken][merkleRoot] -> pair
  function pairs(
    address nft,
    address baseToken,
    bytes32 merkleRoot
  ) external view returns (address);

  /// @notice Creates a new pair.
  /// @param nft The NFT contract address.
  /// @param baseToken The base token contract address.
  /// @param merkleRoot The merkle root for the valid tokenIds.
  /// @return pair The address of the new pair.
  function create(address nft, address baseToken, bytes32 merkleRoot) external returns (address);
}
