pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ModuleLib.sol";
import "./ERC20.sol";
import "./ERC20AdapterLib.sol";
import "./TokenUtils.sol";
import "./BorrowProxyLib.sol";

contract ERC20Adapter {
  using ERC20AdapterLib for *;
  using ModuleLib for *;
  using TokenUtils for *;
  BorrowProxyLib.ProxyIsolate proxyIsolate;
  function getExternalIsolateHandler() external pure returns (ERC20AdapterLib.Isolate memory) {
    return ERC20AdapterLib.getIsolatePointer();
  }
  function repay(address /* moduleAddress */)  public returns (bool) {
    return proxyIsolate.processEscrowForwards();
  }
  function handle(ModuleLib.AssetSubmodulePayload memory payload) public payable {
    (bytes4 sig, bytes memory args) = payload.callData.splitPayload();
    if (sig == ERC20.transfer.selector) {
       ERC20AdapterLib.TransferInputs memory inputs = args.decodeTransferInputs();
       require(proxyIsolate.sendToEscrow(inputs.recipient, payload.to, inputs.amount), "token transfer to escrow wallet failed");
    } else if (sig == ERC20.approve.selector) {
      // do nothing
    } else revert("unsupported token call");
  }
}
