pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Create2.sol";
import "./IModuleRegistryProvider.sol";
import "./AddressSetLib.sol";
import "./ExtLib.sol";
import "./RevertCaptureLib.sol";
import "./SandboxLib.sol";
import "./ModuleLib.sol";

library BorrowProxyLib {
  using ModuleLib for *;
  struct ProxyIsolate {
    address payable masterAddress;
    bool unbound;
    address owner;
    address token;
    uint256 actualizedShift;
    uint256 liquidationIndex;
    uint256 repaymentIndex;
    bool isRepaying;
    bool isLiquidating;
    AddressSetLib.AddressSet liquidationSet;
    AddressSetLib.AddressSet repaymentSet;
  }
  struct ControllerIsolate {
    mapping (address => bytes32) proxyInitializerRecord;
    mapping (address => address) ownerByProxy;
    mapping (address => address) tokenByProxy;
    mapping (address => bool) isKeeper;
  }
  struct Module {
    bool isPrecompiled;
    address assetSubmodule;
    address liquidationSubmodule;
    address repaymentSubmodule;
  }
  struct ModuleDetails {
    ModuleRegistrationType moduleType;
    address target;
    bytes4[] sigs;
  }
  struct ModuleRegistration {
    ModuleRegistrationType moduleType;
    address target;
    bytes4[] sigs;
    Module module;
  }
  enum ModuleRegistrationType {
    UNINITIALIZED,
    BY_CODEHASH,
    BY_ADDRESS
  }
  struct ModuleExecution {
    address to;
    address token;
    Module encapsulated;
  }
  function registryRegisterModule(ModuleRegistry storage registry, ModuleRegistration memory registration) internal {
    if (registration.moduleType == ModuleRegistrationType.BY_CODEHASH) for (uint256 i = 0; i < registration.sigs.length; i++) {
      registerModuleByCodeHash(registry, registration.target, registration.sigs[i], registration.module);
    } else if (registration.moduleType == ModuleRegistrationType.BY_ADDRESS) for (uint256 i = 0; i < registration.sigs.length; i++) {
      registerModuleByAddress(registry, registration.target, registration.sigs[i], registration.module);
    }
  }
  function encodeLiquidate(address liquidationSubmodule) internal pure returns (bytes memory retval) {
    retval = abi.encodeWithSignature("liquidate(address)", liquidationSubmodule);
  }
  function decodeBool(bytes memory input) internal pure returns (bool retval) {
    (retval) = abi.decode(input, (bool));
  }
  function delegateLiquidate(address liquidationSubmodule) internal returns (bool) {
    (bool success, bytes memory retval) = liquidationSubmodule.delegatecall(encodeLiquidate(liquidationSubmodule));
    if (!success) revert(RevertCaptureLib.decodeError(retval));
    return decodeBool(retval);
  }
  function encodeRepay(address repaymentSubmodule) internal pure returns (bytes memory retval) {
    retval = abi.encodeWithSignature("repay(address)", repaymentSubmodule);
  }
  function delegateRepay(address repaymentSubmodule) internal returns (bool) {
    (bool success, bytes memory retval) = repaymentSubmodule.delegatecall(encodeRepay(repaymentSubmodule));
    if (!success) revert(RevertCaptureLib.decodeError(retval));
    return decodeBool(retval);
  }
  function encodeNotify(address liquidationSubmodule, bytes memory payload) internal pure returns (bytes memory retval) {
    retval = abi.encodeWithSignature("notify(address,bytes)", liquidationSubmodule, payload);
  }
  function delegateNotify(address liquidationSubmodule, bytes memory payload) internal returns (bool) {
    (bool success,) = liquidationSubmodule.delegatecall(encodeNotify(liquidationSubmodule, payload));
    return success;
  }
  function delegate(ModuleExecution memory module, bytes memory payload, uint256 value) internal returns (bool, bytes memory) {
    (bool success, bytes memory retval) = module.encapsulated.assetSubmodule.delegatecall{ gas: gasleft() }(ModuleLib.AssetSubmodulePayload({
      moduleAddress: address(uint160(module.encapsulated.assetSubmodule)),
      liquidationSubmodule: module.encapsulated.liquidationSubmodule,
      repaymentSubmodule: module.encapsulated.repaymentSubmodule,
      token: address(uint160(module.token)),
      txOrigin: tx.origin,
      to: address(uint160(module.to)),
      value: value,
      callData: payload
    }).encodeWithSelector());
    return (success, retval);
  }
  function isDefined(Module memory module) internal pure returns (bool) {
    return module.assetSubmodule != address(0x0);
  }
  function isInitialized(ControllerIsolate storage isolate, address proxyAddress) internal view returns (bool) {
    return isolate.proxyInitializerRecord[proxyAddress] != bytes32(uint256(0x0));
  }
  struct ModuleRegistry {
    mapping (bytes32 => Module) modules;
  }
  function isDisbursing(ProxyIsolate storage isolate) internal view returns (bool) {
    return isolate.isLiquidating && isolate.liquidationIndex != isolate.liquidationSet.set.length;
  }
  event BorrowProxyMade(address indexed user, address indexed proxyAddress, bytes record);
  function emitBorrowProxyMade(address user, address proxyAddress, bytes memory record) internal {
    emit BorrowProxyMade(user, proxyAddress, record);
  }
  function computeModuleKeyPreimage(address to, bytes4 signature) internal pure returns (bytes memory result) {
    result = abi.encodePacked(to, signature);
  }
  function computeModuleKey(address to, bytes4 signature) internal pure returns (bytes32) {
    return keccak256(computeModuleKeyPreimage(to, signature));
  }
  function computeCodeResolverKeyPreimage(bytes32 codehash, bytes4 signature) internal pure returns (bytes memory result) {
    result = abi.encodePacked(codehash, signature);
  }
  function computeCodeResolverKey(address to, bytes4 signature) internal view returns (bytes32) {
    bytes32 exthash = ExtLib.getExtCodeHash(to);
    return keccak256(computeCodeResolverKeyPreimage(exthash, signature));
  }
  function resolveModule(ModuleRegistry storage registry, address to, bytes4 sig) internal view returns (Module memory) {
    Module memory module = registry.modules[computeCodeResolverKey(to, sig)];
    if (!isDefined(module)) module = registry.modules[computeModuleKey(to, sig)];
    return module;
  }
  function getModuleExecution(ModuleRegistry storage registry, address to, bytes4 signature) internal view returns (ModuleExecution memory) {
    Module memory encapsulated = resolveModule(registry, to, signature);
    return ModuleExecution({
      encapsulated: encapsulated,
      token: address(0x0), // fill in in the proxy call
      to: to
    });
  }
  function validateProxyRecord(ControllerIsolate storage isolate, address proxyAddress, bytes memory data) internal view returns (bool) {
    return isolate.proxyInitializerRecord[proxyAddress] == keccak256(data);
  }
  function mapProxyRecord(ControllerIsolate storage isolate, address proxyAddress, bytes memory data) internal {
    isolate.proxyInitializerRecord[proxyAddress] = keccak256(data);
  }
  function setProxyOwner(ControllerIsolate storage isolate, address proxyAddress, address identity) internal {
    isolate.ownerByProxy[proxyAddress] = identity;
  }
  function setProxyToken(ControllerIsolate storage isolate, address proxyAddress, address token) internal {
    isolate.tokenByProxy[proxyAddress] = token;
  }
  function getProxyToken(ControllerIsolate storage isolate, address proxyAddress) internal view returns (address) {
    return isolate.tokenByProxy[proxyAddress];
  }
  function getProxyOwner(ControllerIsolate storage isolate, address proxyAddress) internal view returns (address) {
    return isolate.ownerByProxy[proxyAddress];
  }
  function registerModuleByAddress(ModuleRegistry storage registry, address to, bytes4 signature, Module memory module) internal {
    registry.modules[computeModuleKey(to, signature)] = module;
  }
  function registerModuleByCodeHash(ModuleRegistry storage registry, address to, bytes4 signature, Module memory module) internal {
    registry.modules[computeCodeResolverKey(to, signature)] = module;
  }
  function fetchModule(ProxyIsolate storage isolate, address to, bytes4 signature) internal returns (ModuleExecution memory) {
    return ModuleExecution({
      encapsulated: IModuleRegistryProvider(isolate.masterAddress).fetchModuleHandler(to, signature),
      token: isolate.token,
      to: to
    });
  }
}
