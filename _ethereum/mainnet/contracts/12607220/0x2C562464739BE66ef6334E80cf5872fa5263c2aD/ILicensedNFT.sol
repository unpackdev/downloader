// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILicensedNFT {
  function ownerOf(uint256 _tokenId) external view returns (address);

  function authTokenDeployementPaused() external view returns (bool);
}
