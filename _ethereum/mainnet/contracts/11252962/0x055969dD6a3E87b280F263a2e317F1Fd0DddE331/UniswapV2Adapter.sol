pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IUniswapV2Router01.sol";
import "./IERC20.sol";
import "./TokenUtils.sol";
import "./ModuleLib.sol";
import "./UniswapV2AdapterLib.sol";
import "./BorrowProxyLib.sol";
import "./ERC20AdapterLib.sol";
import "./ShifterPool.sol";

contract UniswapV2Adapter {
  using TokenUtils for *;
  using ModuleLib for *;
  using BorrowProxyLib for *;
  using UniswapV2AdapterLib for *;
  using ERC20AdapterLib for *;
  BorrowProxyLib.ProxyIsolate proxyIsolate;
  constructor(address erc20Module) public {
    UniswapV2AdapterLib.Isolate storage isolate = UniswapV2AdapterLib.getIsolatePointer(address(this));
    isolate.erc20Module = erc20Module;
  }
  function validateIsERC20Module(ModuleLib.AssetSubmodulePayload memory payload, address token) internal view returns (bool) {
    UniswapV2AdapterLib.Isolate memory externalIsolate = UniswapV2AdapterLib.getExternalIsolate(payload.moduleAddress);
    require(ShifterPool(proxyIsolate.masterAddress).fetchModuleHandler(token, IERC20.transfer.selector).assetSubmodule == externalIsolate.erc20Module, "asset is not associated with the ERC20 module");
  }
  function getExternalIsolateHandler() external view returns (UniswapV2AdapterLib.Isolate memory) {
    return UniswapV2AdapterLib.getIsolatePointer(address(this));
  }
  function getWETH(ModuleLib.AssetSubmodulePayload memory payload) internal pure returns (address) {
    return IUniswapV2Router01(payload.to).WETH();
  }
  function handle(ModuleLib.AssetSubmodulePayload memory payload) public payable {
    (bytes4 sig, bytes memory args) = payload.callData.splitPayload();
    bool shouldTriggerERC20Handlers = false;
    address escrowWallet = proxyIsolate.deriveNextForwarderAddress();
    address newToken = address(0x0);
    address startToken = address(0x0);
    if (sig == IUniswapV2Router01.swapExactTokensForTokens.selector) {
      UniswapV2AdapterLib.SwapExactTokensForTokensInputs memory inputs = args.decodeSwapExactTokensForTokensInputs();
      address WETH = getWETH(payload);
      (startToken, newToken) = inputs.path.validatePath(WETH);
      validateIsERC20Module(payload, newToken);
      if (inputs.to != address(this)) {
        payload.callData = inputs.changeRecipient(escrowWallet).encodeWithSelector();
        shouldTriggerERC20Handlers = true;
        ERC20AdapterLib.installEscrowRecord(inputs.to, newToken);
      }
    } else if (sig == IUniswapV2Router01.swapTokensForExactTokens.selector) {
      UniswapV2AdapterLib.SwapTokensForExactTokensInputs memory inputs = args.decodeSwapTokensForExactTokensInputs();
      address WETH = getWETH(payload);
      (startToken, newToken) = inputs.path.validatePath(WETH);
      validateIsERC20Module(payload, newToken);
      if (inputs.to != address(this)) {
        payload.callData = inputs.changeRecipient(escrowWallet).encodeWithSelector();
        shouldTriggerERC20Handlers = true;
        ERC20AdapterLib.installEscrowRecord(inputs.to, newToken);
      }
    } else if (sig == IUniswapV2Router01.swapExactETHForTokens.selector) {
      UniswapV2AdapterLib.SwapExactETHForTokensInputs memory inputs = args.decodeSwapExactETHForTokensInputs();
      address WETH = getWETH(payload);
      (startToken, newToken) = inputs.path.validatePath(WETH);
      validateIsERC20Module(payload, newToken);
      if (inputs.to != address(this)) {
        payload.callData = inputs.changeRecipient(escrowWallet).encodeWithSelector();
        shouldTriggerERC20Handlers = true;
        ERC20AdapterLib.installEscrowRecord(inputs.to, newToken);
      }
    } else if (sig == IUniswapV2Router01.swapTokensForExactETH.selector) {
      UniswapV2AdapterLib.SwapExactETHForTokensInputs memory inputs = args.decodeSwapExactETHForTokensInputs();
      address WETH = getWETH(payload);
      (startToken, newToken) = inputs.path.validatePath(WETH);
      validateIsERC20Module(payload, newToken);
      if (inputs.to != address(this)) {
        payload.callData = inputs.changeRecipient(escrowWallet).encodeWithSelector();
        shouldTriggerERC20Handlers = true;
        ERC20AdapterLib.installEscrowRecord(inputs.to, newToken);
      }
    } else if (sig == IUniswapV2Router01.swapExactTokensForETH.selector) {
      UniswapV2AdapterLib.SwapExactTokensForETHInputs memory inputs = args.decodeSwapExactTokensForETHInputs();
      address WETH = getWETH(payload);
      (startToken, newToken) = inputs.path.validatePath(WETH);
      validateIsERC20Module(payload, newToken);
      if (inputs.to != address(this)) {
        payload.callData = inputs.changeRecipient(escrowWallet).encodeWithSelector();
        shouldTriggerERC20Handlers = true;
        ERC20AdapterLib.installEscrowRecord(inputs.to, newToken);
      }
    } else if (sig == IUniswapV2Router01.swapETHForExactTokens.selector) {
      UniswapV2AdapterLib.SwapETHForExactTokensInputs memory inputs = args.decodeSwapETHForExactTokensInputs();
      address WETH = getWETH(payload);
      (startToken, newToken) = inputs.path.validatePath(WETH);
      validateIsERC20Module(payload, newToken);
      if (inputs.to != address(this)) {
        payload.callData = inputs.changeRecipient(escrowWallet).encodeWithSelector();
        shouldTriggerERC20Handlers = true;
        ERC20AdapterLib.installEscrowRecord(inputs.to, newToken);
      }
    } else revert("unsupported contract call");
    if (newToken != address(0x0)) {
      require(payload.liquidationSubmodule.delegateNotify(newToken.encodeLiquidationNotify()), "liquidation module notification failure");
    }
    require(startToken.approveForMaxIfNeeded(payload.to), "failed to approve start token");
    if (shouldTriggerERC20Handlers) proxyIsolate.triggerERC20Handlers(payload.moduleAddress);
    (bool success, bytes memory retval) = payload.to.call{ gas: gasleft(), value: payload.value }(payload.callData);
    ModuleLib.bubbleResult(success, retval);
  }
}
