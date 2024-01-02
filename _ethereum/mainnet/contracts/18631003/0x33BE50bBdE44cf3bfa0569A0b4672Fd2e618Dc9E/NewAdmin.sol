// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./ITimelock.sol";

struct CallData {
  address target;
  uint256 value;
  bytes data;
}

contract NewAdmin {
  ITimelock internal immutable timelock =
      ITimelock(0x78a3eF33cF033381FEB43ba4212f2Af5A5A0a2EA);
  address public owner;

  constructor(address _owner) {
      owner = _owner;
  }

  error NotOwner();

  modifier onlyOwner() {
      if (msg.sender != owner) revert NotOwner();
      _;
  }

  function acceptAdmin() external {
      timelock.acceptAdmin();
  }

  function transferOwnership(address newOwner) external onlyOwner {
      owner = newOwner;
  }

  receive() external payable {}

  fallback() external {}

  function multicall(
      CallData[] calldata calls,
      bool revertOnFailure
  ) external onlyOwner {
      for (uint256 i = 0; i < calls.length; i++) {
          CallData memory callData = calls[i];
          address target = callData.target;
          uint256 value = callData.value;
          bytes memory data = callData.data;
          assembly {
              let success := call(
                  gas(),
                  target,
                  value,
                  add(data, 0x20),
                  mload(data),
                  0,
                  0
              )
              if gt(revertOnFailure, success) {
                  returndatacopy(0, 0, returndatasize())
                  revert(0, returndatasize())
              }
          }
      }
  }

  function delegateCall(
      address target,
      bytes memory data,
      bool revertOnFailure
  ) external onlyOwner {
      assembly {
          let success := delegatecall(
              gas(),
              target,
              add(data, 0x20),
              mload(data),
              0,
              0
          )
          if gt(revertOnFailure, success) {
              returndatacopy(0, 0, returndatasize())
              revert(0, returndatasize())
          }
      }
  }
}