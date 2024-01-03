pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./UniswapV2Adapter.sol";
import "./IUniswapV2Router01.sol";
import "./BorrowProxyLib.sol";
import "./ShifterBorrowProxyLib.sol";
import "./Create2.sol";
import "./ModuleLib.sol";
import "./AddressSetLib.sol";

library UniswapV2AdapterLib {
  using BorrowProxyLib for *;
  using AddressSetLib for *;
  using ShifterBorrowProxyLib for *;
  bytes32 constant ETHER_FORWARDER_SALT = 0x3e8d8e49b9a35f50b96f6ba4b93e0fc6c1d66a2e1c04975ef848d7031c8158a4; // keccak("uniswap-adapter.ether-forwarder")
  struct Isolate {
    uint256 liquidityMinimum;
    address erc20Module;
  }
  struct SwapExactTokensForTokensInputs {
    uint256 amountIn;
    uint256 amountOutMin;
    address[] path;
    address to;
    uint256 deadline;
  }
  function decodeSwapExactTokensForTokensInputs(bytes memory args) internal pure returns (SwapExactTokensForTokensInputs memory) {
    (uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline) = abi.decode(args, (uint256, uint256, address[], address, uint256));
    return SwapExactTokensForTokensInputs({
      amountIn: amountIn,
      amountOutMin: amountOutMin,
      path: path,
      to: to,
      deadline: deadline
    });
  }
  function changeRecipient(SwapExactTokensForTokensInputs memory inputs, address newRecipient) internal pure returns (SwapExactTokensForTokensInputs memory) {
    return SwapExactTokensForTokensInputs({
      amountIn: inputs.amountIn,
      amountOutMin: inputs.amountOutMin,
      path: inputs.path,
      to: newRecipient,
      deadline: inputs.deadline
    });
  }
  function encodeWithSelector(SwapExactTokensForTokensInputs memory inputs) internal pure returns (bytes memory callData) {
    callData = abi.encodeWithSelector(IUniswapV2Router01.swapExactTokensForTokens.selector, inputs.amountIn, inputs.amountOutMin, inputs.path, inputs.to, inputs.deadline);
  }
  struct SwapTokensForExactTokensInputs {
    uint256 amountOut;
    uint256 amountInMax;
    address[] path;
    address to;
    uint256 deadline;
  }
  function decodeSwapTokensForExactTokensInputs(bytes memory args) internal pure returns (SwapTokensForExactTokensInputs memory) {
    (uint256 amountOut, uint256 amountInMax, address[] memory path, address to, uint256 deadline) = abi.decode(args, (uint256, uint256, address[], address, uint256));
    return SwapTokensForExactTokensInputs({
      amountOut: amountOut,
      amountInMax: amountInMax,
      path: path,
      to: to,
      deadline: deadline
    });
  }
  function changeRecipient(SwapTokensForExactTokensInputs memory inputs, address newRecipient) internal pure returns (SwapTokensForExactTokensInputs memory) {
    return SwapTokensForExactTokensInputs({
      amountOut: inputs.amountOut,
      amountInMax: inputs.amountInMax,
      path: inputs.path,
      to: newRecipient,
      deadline: inputs.deadline
    });
  }
  function encodeWithSelector(SwapTokensForExactTokensInputs memory inputs) internal pure returns (bytes memory callData) {
    callData = abi.encodeWithSelector(IUniswapV2Router01.swapTokensForExactTokens.selector, inputs.amountOut, inputs.amountInMax, inputs.path, inputs.to, inputs.deadline);
  }
  struct SwapExactETHForTokensInputs {
    uint256 amountOutMin;
    address[] path;
    address to;
    uint256 deadline;
  }
  function decodeSwapExactETHForTokensInputs(bytes memory args) internal pure returns (SwapExactETHForTokensInputs memory) {
    (uint256 amountOutMin, address[] memory path, address to, uint256 deadline) = abi.decode(args, (uint256, address[], address, uint256));
    return SwapExactETHForTokensInputs({
      amountOutMin: amountOutMin,
      path: path,
      to: to,
      deadline: deadline
    });
  }
  function changeRecipient(SwapExactETHForTokensInputs memory inputs, address newRecipient) internal pure returns (SwapExactETHForTokensInputs memory) {
    return SwapExactETHForTokensInputs({
      amountOutMin: inputs.amountOutMin,
      path: inputs.path,
      to: newRecipient,
      deadline: inputs.deadline
    });
  }
  function encodeWithSelector(SwapExactETHForTokensInputs memory inputs) internal pure returns (bytes memory callData) {
    callData = abi.encodeWithSelector(IUniswapV2Router01.swapExactETHForTokens.selector, inputs.amountOutMin, inputs.path, inputs.to, inputs.deadline);
  }
  struct SwapTokensForExactETHInputs {
    uint256 amountOut;
    uint256 amountInMax;
    address[] path;
    address to;
    uint256 deadline;
  }
  function decodeSwapTokensForExactETHInputs(bytes memory args) internal pure returns (SwapTokensForExactETHInputs memory) {
    (uint256 amountOut, uint256 amountInMax, address[] memory path, address to, uint256 deadline) = abi.decode(args, (uint256, uint256, address[], address, uint256));
    return SwapTokensForExactETHInputs({
      amountOut: amountOut,
      amountInMax: amountInMax,
      path: path,
      to: to,
      deadline: deadline
    });
  }
  function changeRecipient(SwapTokensForExactETHInputs memory inputs, address newRecipient) internal pure returns (SwapTokensForExactETHInputs memory) {
    return SwapTokensForExactETHInputs({
      amountOut: inputs.amountOut,
      amountInMax: inputs.amountInMax,
      path: inputs.path,
      to: newRecipient,
      deadline: inputs.deadline
    });
  }
  function encodeWithSelector(SwapTokensForExactETHInputs memory inputs) internal pure returns (bytes memory callData) {
    callData = abi.encodeWithSelector(IUniswapV2Router01.swapTokensForExactETH.selector, inputs.amountOut, inputs.amountInMax, inputs.path, inputs.to, inputs.deadline);
  }
  struct SwapExactTokensForETHInputs {
    uint256 amountIn;
    uint256 amountOutMin;
    address[] path;
    address to;
    uint256 deadline;
  }
  function decodeSwapExactTokensForETHInputs(bytes memory args) internal pure returns (SwapExactTokensForETHInputs memory) {
    (uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline) = abi.decode(args, (uint256, uint256, address[], address, uint256));
    return SwapExactTokensForETHInputs({
      amountIn: amountIn,
      amountOutMin: amountOutMin,
      path: path,
      to: to,
      deadline: deadline
    });
  }
  function changeRecipient(SwapExactTokensForETHInputs memory inputs, address newRecipient) internal pure returns (SwapExactTokensForETHInputs memory) {
    return SwapExactTokensForETHInputs({
      amountIn: inputs.amountIn,
      amountOutMin: inputs.amountOutMin,
      path: inputs.path,
      to: newRecipient,
      deadline: inputs.deadline
    });
  }
  function encodeWithSelector(SwapExactTokensForETHInputs memory inputs) internal pure returns (bytes memory callData) {
    callData = abi.encodeWithSelector(IUniswapV2Router01.swapExactTokensForETH.selector, inputs.amountIn, inputs.amountOutMin, inputs.path, inputs.to, inputs.deadline);
  }
  struct SwapETHForExactTokensInputs {
    uint256 amountOut;
    address[] path;
    address to;
    uint256 deadline;
  }
  function decodeSwapETHForExactTokensInputs(bytes memory args) internal pure returns (SwapETHForExactTokensInputs memory) {
    (uint256 amountOut, address[] memory path, address to, uint256 deadline) = abi.decode(args, (uint256, address[], address, uint256));
    return SwapETHForExactTokensInputs({
      amountOut: amountOut,
      path: path,
      to: to,
      deadline: deadline
    });
  }
  function changeRecipient(SwapETHForExactTokensInputs memory inputs, address newRecipient) internal pure returns (SwapETHForExactTokensInputs memory) {
    return SwapETHForExactTokensInputs({
      amountOut: inputs.amountOut,
      path: inputs.path,
      to: newRecipient,
      deadline: inputs.deadline
    });
  }
  function encodeWithSelector(SwapETHForExactTokensInputs memory inputs) internal pure returns (bytes memory callData) {
    callData = abi.encodeWithSelector(IUniswapV2Router01.swapETHForExactTokens.selector, inputs.amountOut, inputs.path, inputs.to, inputs.deadline);
  }
  function computeIsolatePointer(address instance) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked("isolate.uniswap-v2-adapter", instance)));
  }
  function validatePath(address[] memory path, address WETH) internal pure returns (address begin, address destination) {
    if (path.length < 2) revert("path too short, must be 3 elements");
    if (path.length > 3 || !(path[0] == WETH || path[1] == WETH)) revert("path must be 2 or 3 items and include WETH");
    return (path[0], path[path.length - 1]);
  }
  function generatePathForToken(address startToken, address WETH, address token) internal pure returns (address[] memory path) {
    path = new address[](3);
    path[0] = startToken;
    path[1] = WETH;
    path[2] = token;
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
  function getIsolatePointer(address instance) internal pure returns (Isolate storage) {
    return toIsolatePointer(computeIsolatePointer(instance));
  }
  function getExternalIsolate(address payable moduleAddress) internal view returns (Isolate memory) {
    return UniswapV2Adapter(moduleAddress).getExternalIsolateHandler();
  }
  function encodeLiquidationNotify(address newToken) internal pure returns (bytes memory result) {
    result = abi.encode(newToken);
  }
  function triggerERC20Handlers(BorrowProxyLib.ProxyIsolate storage proxyIsolate, address moduleAddress) internal {
    Isolate memory isolate = UniswapV2Adapter(moduleAddress).getExternalIsolateHandler();
    proxyIsolate.repaymentSet.insert(isolate.erc20Module);
  }
}
