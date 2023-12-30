pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SliceLib.sol";

interface IModule {
  function handle(ModuleLib.AssetSubmodulePayload calldata) external payable;
}

library ModuleLib {
  address payable constant ETHER_ADDRESS = 0x0000000000000000000000000000000000000000;
  function GET_ETHER_ADDRESS() internal pure returns (address payable) {
    return ETHER_ADDRESS;
  }
  function cast(uint256 v) internal pure returns (uint256) {
    return v;
  }
  function splitPayload(bytes memory payload) internal pure returns (bytes4 sig, bytes memory args) {
    sig = bytes4(uint32(uint256(SliceLib.asWord(SliceLib.toSlice(payload, 0, 4)))));
    args = SliceLib.copy(SliceLib.toSlice(payload, 4));
  }
  struct AssetSubmodulePayload {
    address payable moduleAddress;
    address liquidationSubmodule;
    address repaymentSubmodule;
    address payable token;
    address payable txOrigin;
    address payable to;
    uint256 value;
    bytes callData;
  }
  function encodeWithSelector(AssetSubmodulePayload memory input) internal pure returns (bytes memory result) {
    result = abi.encodeWithSelector(IModule.handle.selector, input);
  }
  function bubbleResult(bool success, bytes memory retval) internal pure {
    assembly {
      if iszero(success) {
        revert(add(0x20, retval), mload(retval))
      }
      return(add(0x20, retval), mload(retval))
    }
  }
}
