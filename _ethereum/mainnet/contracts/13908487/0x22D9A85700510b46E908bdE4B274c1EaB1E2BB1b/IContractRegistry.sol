// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

/**
 * @dev External interface of ContractRegistry.
 */
interface IContractRegistry {
  function getContract(bytes32 _name) external view returns (address);
}
