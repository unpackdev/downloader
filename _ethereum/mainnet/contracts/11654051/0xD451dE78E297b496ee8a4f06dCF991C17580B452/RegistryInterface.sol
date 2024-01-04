// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

interface RegistryInterface {
  function registerContract(address[] calldata parties, address contractAddress)
    external;

  function isContractRegistered(address contractAddress)
    external
    view
    returns (bool);

  function getRegisteredContracts(address party)
    external
    view
    returns (address[] memory);

  function getAllRegisteredContracts() external view returns (address[] memory);

  function addPartyToContract(address party) external;

  function removePartyFromContract(address party) external;

  function isPartyMemberOfContract(address party, address contractAddress)
    external
    view
    returns (bool);
}
