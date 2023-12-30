// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ECDSA.sol";
import "./RevertDecoderLib.sol";
import "./SliceLib.sol";
import "./ConcatLib.sol";
import "./StringLib.sol";
import "./console.sol";

library FauxblocksLib {
  using SliceLib for *;
  using StringLib for *;
  using ConcatLib for *;
  bytes32 constant BYTES4_MASK = 0xffffffff00000000000000000000000000000000000000000000000000000000;
  function toSignature(bytes memory signature) internal pure returns (bytes4 extracted) {
    bytes memory slice = signature.toSlice(0, 4).copy();
    bytes4 word;
    bytes32 mask = BYTES4_MASK;
    assembly {
      word := and(mask, mload(add(0x20, slice)))
    }
    extracted = word;
  }
  enum TransactionType {
    REJECT,
    CALL,
    DELEGATECALL
  }
  struct Transaction {
    address payable to;
    uint256 value;
    uint256 gas; // use 0 to use max available gas
    bytes data;
  }
  struct Approval {
    uint256 nonce;
    bytes signature;
  }
  function gasAmount(Transaction memory trx) internal view returns (uint256 result) {
    if (trx.gas == 0) result = gasleft();
    else result = trx.gas;
  }
  function hashTransaction(Transaction memory trx) internal pure returns (bytes32 result) {
    result = keccak256(abi.encodePacked(trx.to, trx.value, trx.gas, trx.data));
  }
  function hashApprovalWithTransaction(Transaction memory trx, Approval memory approval) internal pure returns (bytes32 result) {
    result = keccak256(abi.encodePacked(hashTransaction(trx), approval.nonce));
  }
  function recoverAddress(Transaction memory trx, Approval memory approval) internal pure returns (address result) {
    result = ECDSA.recover(ECDSA.toEthSignedMessageHash(hashApprovalWithTransaction(trx, approval)), approval.signature);
  }
  function isUnique(address[] memory set, address item, uint256 idx) internal pure returns (bool) {
    for (uint256 i = 0; i < set.length; i++) {
      if (i == idx) continue;
      if (set[i] == item) return false;
    }
    return true;
  }
  function allUnique(address[] memory set) internal pure returns (bool) {
    for (uint256 i = 0; i < set.length; i++) {
      if (!isUnique(set, set[i], i)) return false;
    }
    return true;
  }
  function sendTransaction(Transaction memory trx, TransactionType code) internal returns (bytes memory result) {
    if (code == TransactionType.DELEGATECALL) {
      (bool success, bytes memory retval) = trx.to.delegatecall{ gas: gasAmount(trx) }(trx.data);
      if (!success) revert(RevertDecoderLib.decodeError(retval));
      return retval;
    } else if (code == TransactionType.CALL) {
      (bool success, bytes memory retval) = trx.to.call{ value: trx.value, gas: gasAmount(trx) }(trx.data);
      if (!success) revert(RevertDecoderLib.decodeError(retval));
      return retval;
    } else {
      revert("Invalid transaction type");
    }
  }
  function packContext(Transaction memory trx, address controller, bytes memory context) internal pure returns (Transaction memory) {
    trx.data = trx.data.concat(context).concat(abi.encode(uint256(context.length), controller));
    return trx;
  }
  function getController() internal pure returns (address controller) {
    uint256 word;
    assembly {
      word := calldataload(sub(calldatasize(), 0x20))
    }
    controller = address(word);
  }
  function getContext() internal pure returns (bytes memory context) {
    uint256 length;
    uint256 sz;
    assembly {
      sz := calldatasize()
      length := calldataload(sub(sz, 0x40))
    }
    context = new bytes(length);
    assembly {
      calldatacopy(add(context, 0x20), sub(sz, add(0x40, length)), length)
    }
  }
}
