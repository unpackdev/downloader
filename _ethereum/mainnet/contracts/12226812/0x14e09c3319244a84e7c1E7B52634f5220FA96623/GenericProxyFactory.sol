// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ClonesUpgradeable.sol";

/// @title PoolTogether Generic Minimal ProxyFactory
/// @notice EIP-1167 Minimal proxy factory pattern for creating proxy contracts
contract GenericProxyFactory{
  
  ///@notice Event fired when minimal proxy has been created
  event ProxyCreated(address indexed created, address indexed implementation);

  /// @notice Create a proxy contract for given instance
  /// @param _instance Contract implementation which the created contract will point at
  /// @param _data Data which is to be called after the proxy contract is created
  function create(address _instance, bytes calldata _data) public returns (address instanceCreated, bytes memory result) {
    
    instanceCreated = ClonesUpgradeable.clone(_instance);
    emit ProxyCreated(instanceCreated, _instance);

    if(_data.length > 0) {
      return callContract(instanceCreated, _data);
    }

    return (instanceCreated, "");  
  }

  /// @notice Create a proxy contract with a deterministic address using create2
  /// @param _instance Contract implementation which the created contract will point at
  /// @param _salt Salt which is used as the create2 salt
  /// @param _data Data which is to be called after the proxy contract is created
  function create2(address _instance, bytes32 _salt, bytes calldata _data) public returns (address instanceCreated, bytes memory result) {

    instanceCreated = ClonesUpgradeable.cloneDeterministic(_instance, _salt);
    emit ProxyCreated(instanceCreated, _instance);

    if(_data.length > 0) {
      return callContract(instanceCreated, _data);
    }

    return (instanceCreated, "");
  }

  /// @notice Calculates what the proxy address would be when deterministically created
  /// @param _master Contract implementation which the created contract will point at
  /// @param _salt Salt which would be used as the create2 salt
  /// @return Deterministic address for given master code and salt using create2
  function predictDeterministicAddress(address _master, bytes32 _salt) public view returns (address) {
    return ClonesUpgradeable.predictDeterministicAddress(_master, _salt, address(this));
  }

  /// @notice Calls the instance contract with the specified data
  /// @dev Will revert if call unsuccessful 
  /// @param target Call target contract
  /// @param _data Data for contract call
  /// @return Tuple of the address called contract and the return data from the call
  function callContract(address target, bytes memory _data) internal returns (address, bytes memory) {
    (bool success, bytes memory returnData) = target.call(_data);
    require(success, string(returnData));
    return (target, returnData);
  }

}
