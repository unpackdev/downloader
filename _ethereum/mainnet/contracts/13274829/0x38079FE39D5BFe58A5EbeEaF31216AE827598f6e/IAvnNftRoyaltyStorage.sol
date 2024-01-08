// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAvnNftRoyaltyStorage {

  struct Royalty {
    address recipient;
    uint32 partsPerMil;
  }

  event LogPermissionUpdated(address partnerContract, bool status);

  function setPermission(address partnerContract, bool status) external; // onlyOwner
  function setRoyaltyId(uint256 batchId, uint256 nftId) external; // onlyPermitted
  function setRoyalties(uint256 id, Royalty[] calldata royalties) external; // onlyPermitted
  function getRoyalties(uint256 id) external view returns(Royalty[] memory);
}