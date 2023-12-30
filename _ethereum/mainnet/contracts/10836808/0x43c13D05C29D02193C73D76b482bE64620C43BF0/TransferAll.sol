pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./PreprocessorLib.sol";
import "./IERC20.sol";
import "./ShifterBorrowProxyLib.sol";
import "./SandboxLib.sol";
import "./BorrowProxyLib.sol";

contract TransferAll {
  using PreprocessorLib for *;
  BorrowProxyLib.ProxyIsolate isolate;
  address public target;
  function setup(bytes memory consData) public {
    (target) = abi.decode(consData, (address));
  }
  function execute(bytes memory data) view public returns (ShifterBorrowProxyLib.InitializationAction[] memory) {
    SandboxLib.ExecutionContext memory context = data.toContext();
    address token = isolate.token;
    return isolate.token.sendTransaction(abi.encodeWithSelector(IERC20.transfer.selector, TransferAll(context.preprocessorAddress).target(), IERC20(token).balanceOf(address(this))));
  }
}
