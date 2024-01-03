pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Create2.sol";
import "./IERC20.sol";
import "./ModuleLib.sol";
import "./AssetForwarder.sol";
import "./AssetForwarderLib.sol";
import "./ERC20Adapter.sol";
import "./BorrowProxyLib.sol";
import "./StringLib.sol";
import "./ShifterPoolLib.sol";
import "./TokenUtils.sol";
import "./FactoryLib.sol";
import "./ShifterPool.sol";

library ERC20AdapterLib {
  using ShifterPoolLib for *;
  using TokenUtils for *;
  using StringLib for *;
  struct EscrowRecord {
    address recipient;
    address token;
  }
  struct Isolate {
    EscrowRecord[] payments;
    bool isProcessing;
    uint256 processed;
  }
  function isDone(Isolate storage isolate) internal view returns (bool) {
    return !isolate.isProcessing && isolate.payments.length == isolate.processed;
  }
  function computeIsolatePointer() public pure returns (uint256) {
    return uint256(keccak256("isolate.erc20-adapter"));
  }
  function computeForwarderSalt(uint256 index) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(index));
  }
  function computeForwarderAddress(BorrowProxyLib.ProxyIsolate storage proxyIsolate, uint256 index) internal view returns (address) {
    return FactoryLib.deriveInstanceAddress(proxyIsolate.masterAddress, ShifterPool(proxyIsolate.masterAddress).getAssetForwarderImplementationHandler(), keccak256(abi.encodePacked(AssetForwarderLib.GET_ASSET_FORWARDER_IMPLEMENTATION_SALT(), address(this), computeForwarderSalt(index))));
  }
  function liquidate(BorrowProxyLib.ProxyIsolate storage proxyIsolate) internal returns (bool) {
    return processEscrowReturns(proxyIsolate);
  }
  struct TransferInputs {
    address recipient;
    uint256 amount;
  }
  function decodeTransferInputs(bytes memory args) internal pure returns (TransferInputs memory) {
    (address recipient, uint256 amount) = abi.decode(args, (address, uint256));
    return TransferInputs({
      recipient: recipient,
      amount: amount
    });
  }
  event Log(address indexed data);
  function forwardEscrow(BorrowProxyLib.ProxyIsolate storage proxyIsolate, EscrowRecord memory record, uint256 index) internal {
    address forwarder = proxyIsolate.deployAssetForwarder(computeForwarderSalt(index));
    emit Log(forwarder);
    emit Log(computeForwarderAddress(proxyIsolate, index));
    AssetForwarder(forwarder).forwardAsset(address(uint160(record.recipient)), record.token);
  }
  function returnEscrow(BorrowProxyLib.ProxyIsolate storage proxyIsolate, EscrowRecord memory record, uint256 index) internal {
    address forwarder = proxyIsolate.deployAssetForwarder(computeForwarderSalt(index));
    AssetForwarder(forwarder).forwardAsset(address(uint160(address(this))), record.token);
  }
  uint256 constant MINIMUM_GAS_TO_PROCESS = 5e5;
  uint256 constant MAX_RECORDS = 100;
  function processEscrowForwards(BorrowProxyLib.ProxyIsolate storage proxyIsolate) internal returns (bool) {
    Isolate storage isolate = getIsolatePointer();
    if (!isolate.isProcessing) isolate.isProcessing = true;
    for (uint256 i = isolate.processed; i < isolate.payments.length; i++) {
      if (gasleft() < MINIMUM_GAS_TO_PROCESS) {
        isolate.processed = i;
        return false;
      } else {
        forwardEscrow(proxyIsolate, isolate.payments[i], i);
      }
    }
    return true;
  }
  function processEscrowReturns(BorrowProxyLib.ProxyIsolate storage proxyIsolate) internal returns (bool) {
    Isolate storage isolate = getIsolatePointer();
    if (!isolate.isProcessing) isolate.isProcessing = true;
    for (uint256 i = isolate.processed; i < isolate.payments.length; i++) {
      if (gasleft() < MINIMUM_GAS_TO_PROCESS) {
        isolate.processed = i;
        return false;
      } else {
        returnEscrow(proxyIsolate, isolate.payments[i], i);
      }
    }
    return true;
  }
  function sendToEscrow(BorrowProxyLib.ProxyIsolate storage proxyIsolate, address recipient, address token, uint256 amount) internal returns (bool) {
     Isolate storage isolate = getIsolatePointer();
     address escrowWallet = computeForwarderAddress(proxyIsolate, isolate.payments.length);
     installEscrowRecord(recipient, token);
     return token.sendToken(escrowWallet, amount);
  }
  function installEscrowRecord(address recipient, address token) internal {
    Isolate storage isolate = getIsolatePointer();
    isolate.payments.push(EscrowRecord({
      recipient: recipient,
      token: token
    }));
  }
  function deriveNextForwarderAddress(BorrowProxyLib.ProxyIsolate storage proxyIsolate) internal view returns (address) {
    Isolate storage isolate = getIsolatePointer();
    return computeForwarderAddress(proxyIsolate, isolate.payments.length);
  }
  function getCastStorageType() internal pure returns (function (uint256) internal pure returns (Isolate storage) swap) {
    function (uint256) internal returns (uint256) cast = ModuleLib.cast;
    assembly {
      swap := cast
    }
  }
  function toIsolatePointer(uint256 key) internal pure returns (Isolate storage) {
    return getCastStorageType()(key);
  }
  function getIsolatePointer() internal pure returns (Isolate storage) {
    return toIsolatePointer(computeIsolatePointer());
  }
}
