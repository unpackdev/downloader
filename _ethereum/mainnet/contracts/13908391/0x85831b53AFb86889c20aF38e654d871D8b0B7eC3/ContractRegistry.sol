// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./IACLRegistry.sol";
import "./IContractRegistry.sol";

/**
 * @dev This Contract holds reference to all our contracts. Every contract A that needs to interact with another contract B calls this contract
 * to ask for the address of B.
 * This allows us to update addresses in one central point and reduces constructing and management overhead.
 */
contract ContractRegistry is IContractRegistry {
  struct Contract {
    address contractAddress;
    bytes32 version;
  }

  /* ========== STATE VARIABLES ========== */

  IACLRegistry public aclRegistry;

  mapping(bytes32 => Contract) public contracts;
  bytes32[] public contractNames;

  /* ========== EVENTS ========== */

  event ContractAdded(bytes32 _name, address _address, bytes32 _version);
  event ContractUpdated(bytes32 _name, address _address, bytes32 _version);
  event ContractDeleted(bytes32 _name);

  /* ========== CONSTRUCTOR ========== */

  constructor(IACLRegistry _aclRegistry) {
    aclRegistry = _aclRegistry;
    contracts[keccak256("ACLRegistry")] = Contract({contractAddress: address(_aclRegistry), version: keccak256("1")});
    contractNames.push(keccak256("ACLRegistry"));
  }

  /* ========== VIEW FUNCTIONS ========== */

  function getContractNames() external view returns (bytes32[] memory) {
    return contractNames;
  }

  function getContract(bytes32 _name) external view override returns (address) {
    return contracts[_name].contractAddress;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function addContract(
    bytes32 _name,
    address _address,
    bytes32 _version
  ) external {
    aclRegistry.requireRole(keccak256("DAO"), msg.sender);
    require(contracts[_name].contractAddress == address(0), "contract already exists");
    contracts[_name] = Contract({contractAddress: _address, version: _version});
    contractNames.push(_name);
    emit ContractAdded(_name, _address, _version);
  }

  function updateContract(
    bytes32 _name,
    address _newAddress,
    bytes32 _version
  ) external {
    aclRegistry.requireRole(keccak256("DAO"), msg.sender);
    require(contracts[_name].contractAddress != address(0), "contract doesnt exist");
    contracts[_name] = Contract({contractAddress: _newAddress, version: _version});
    emit ContractUpdated(_name, _newAddress, _version);
  }

  function deleteContract(bytes32 _name, uint256 _contractIndex) external {
    aclRegistry.requireRole(keccak256("DAO"), msg.sender);
    require(contracts[_name].contractAddress != address(0), "contract doesnt exist");
    require(contractNames[_contractIndex] == _name, "this is not the contract you are looking for");
    delete contracts[_name];
    delete contractNames[_contractIndex];
    emit ContractDeleted(_name);
  }
}
