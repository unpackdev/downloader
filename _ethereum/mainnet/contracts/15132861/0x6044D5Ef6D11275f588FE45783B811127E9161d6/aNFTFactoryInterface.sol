// SPDX-License-Identifier: GPL-3.0

/// @title: aNFT Factory Interface
/// @author: circle.xyz

pragma solidity 0.8.13;

interface aNFTFactoryInterface {

  function getPublicMintSigner() external view returns (address);
  function markMessageAsUsed(bytes32 msgHash) external;

}