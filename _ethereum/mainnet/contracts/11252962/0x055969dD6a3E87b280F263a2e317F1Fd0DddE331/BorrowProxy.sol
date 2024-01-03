// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

import "./BorrowProxyLib.sol";
import "./RevertCaptureLib.sol";
import "./SliceLib.sol";
import "./IShifter.sol";
import "./IBorrowProxyController.sol";
import "./AddressSetLib.sol";
import "./ModuleLib.sol";

contract BorrowProxy {
  using SliceLib for *;
  using BorrowProxyLib for *;
  using AddressSetLib for *;
  BorrowProxyLib.ProxyIsolate isolate;
  modifier onlyOwnerOrPool {
   require(msg.sender == isolate.owner || msg.sender == isolate.masterAddress || msg.sender == address(this), "borrow proxy can only be used by borrower");
    _;
  }
  function setup(address owner, address token, bool unbound) public returns (bool) {
    require(isolate.owner == address(0x0), "can't initialize twice");
    isolate.masterAddress = msg.sender;
    isolate.owner = owner;
    isolate.unbound = unbound;
    isolate.token = token;
    return true;
  }
  function validateProxyRecord(bytes memory record) internal returns (bool) {
    return IBorrowProxyController(isolate.masterAddress).validateProxyRecordHandler(record);
  }
  function proxy(address to, uint256 value, bytes memory payload) public onlyOwnerOrPool {
    require(to != isolate.masterAddress, "can't target the ShifterPool");
    bytes4 sig = bytes4(uint32(uint256(payload.toSlice(0, 4).asWord())));
    BorrowProxyLib.ModuleExecution memory module = isolate.fetchModule(to, sig);
    module.token = isolate.token;
    if (isolate.unbound && !module.encapsulated.isPrecompiled) {
      (bool success, bytes memory retval) = to.call{
        value: value
      }(payload);
      if (!success) revert(RevertCaptureLib.decodeError(retval));
      ModuleLib.bubbleResult(success, retval);
      return;
    }
    require(module.encapsulated.isDefined(), "function handler not registered");
    (bool success, bytes memory retval) = module.delegate(payload, value);
    if (!success) revert(RevertCaptureLib.decodeError(retval));
    if (module.encapsulated.liquidationSubmodule != address(0x0)) isolate.liquidationSet.insert(module.encapsulated.liquidationSubmodule);
    if (module.encapsulated.repaymentSubmodule != address(0x0)) {
      isolate.repaymentSet.insert(module.encapsulated.repaymentSubmodule);
    }
    ModuleLib.bubbleResult(success, retval);
  }
  receive() external payable virtual {
    // just receive ether, do nothing
  } 
  fallback() external payable virtual {}
}
