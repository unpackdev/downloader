pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./AddressSetLib.sol";
import "./BorrowProxyLib.sol";
import "./IERC20.sol";
import "./TokenUtils.sol";
import "./SimpleBurnLiquidationModuleLib.sol";
import "./ERC20AdapterLib.sol";
import "./UniswapV2AdapterLib.sol";
import "./IUniswapV2Router01.sol";
import "./ShifterPool.sol";
import "./StringLib.sol";

contract SimpleBurnLiquidationModule {
  using StringLib for *;
  using AddressSetLib for *;
  using TokenUtils for *;
  using UniswapV2AdapterLib for *;
  BorrowProxyLib.ProxyIsolate proxyIsolate;
  constructor(address routerAddress, address erc20Module) public {
    SimpleBurnLiquidationModuleLib.Isolate storage isolate = SimpleBurnLiquidationModuleLib.getIsolatePointer();
    isolate.routerAddress = routerAddress;
    isolate.erc20Module = erc20Module;
  }
  function notify(address /* moduleAddress */, bytes memory payload) public returns (bool) {
    (address token) = abi.decode(payload, (address));
    SimpleBurnLiquidationModuleLib.Isolate storage isolate = SimpleBurnLiquidationModuleLib.getIsolatePointer();
    isolate.toLiquidate.insert(token);
    return true;
  }
  function fetchExternals(address moduleAddress) internal view returns (address routerAddress, address erc20Module) {
    (routerAddress, erc20Module) = SimpleBurnLiquidationModule(moduleAddress).getExternalIsolateHandler();
  }
  function fetchLiquidityToken(address liquidateTo) internal view returns (address) {
    return ShifterPool(proxyIsolate.masterAddress).getLiquidityTokenForTokenHandler(liquidateTo);
  }
  function getWETH(IUniswapV2Router01 router) internal pure returns (address) {
    return router.WETH();
  }
  function liquidate(address moduleAddress) public returns (bool) {
    if (!ERC20AdapterLib.liquidate(proxyIsolate)) return false;
    SimpleBurnLiquidationModuleLib.Isolate storage isolate = SimpleBurnLiquidationModuleLib.getIsolatePointer();
    address liquidateTo = address(uint160(proxyIsolate.token));
    (address routerAddress, /* address erc20Module */) = fetchExternals(moduleAddress);
    IUniswapV2Router01 router = IUniswapV2Router01(routerAddress);
    address WETH = getWETH(router);
    uint256 i;
    for (i = isolate.liquidated; i < isolate.toLiquidate.set.length; i++) {
      address tokenAddress = isolate.toLiquidate.set[i];
      if (liquidateTo == tokenAddress) continue;
      if (gasleft() < 3e5) {
        isolate.liquidated = i;
        return false;
      }
      uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
      address[] memory path = UniswapV2AdapterLib.generatePathForToken(tokenAddress, WETH, liquidateTo);
      tokenAddress.approveForMaxIfNeeded(address(router));
      router.swapExactTokensForTokens(tokenBalance, 1, path, address(this), block.timestamp + 1);
    }
    isolate.liquidated = i;
    return true;
  }
  function getExternalIsolateHandler() external view returns (address, address) {
    SimpleBurnLiquidationModuleLib.Isolate storage isolate = SimpleBurnLiquidationModuleLib.getIsolatePointer();
    return (isolate.routerAddress, isolate.erc20Module);
  }
}
