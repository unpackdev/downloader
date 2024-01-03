pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ModuleLib.sol";
import "./CurveAdapterLib.sol";
import "./TokenUtils.sol";
import "./BorrowProxyLib.sol";
import "./ICurve.sol";

contract CurveAdapter {
  using ModuleLib for *;
  using CurveAdapterLib for *;
  using BorrowProxyLib for *;
  using TokenUtils for *;
  constructor(address curveAddress) public {
    CurveAdapterLib.Isolate storage isolate = CurveAdapterLib.getIsolatePointer(address(this));
    isolate.curveAddress = curveAddress;
  }
  function getExternalIsolateHandler() external view returns (CurveAdapterLib.Isolate memory isolate) {
    isolate = CurveAdapterLib.getIsolatePointer(address(this));
  }
  function handle(ModuleLib.AssetSubmodulePayload memory payload) public payable {
    require(payload.to == CurveAdapter(payload.moduleAddress).getExternalIsolateHandler().curveAddress, "CurveAdapter instance must map one to one with a live curve.fi instance");
    (bytes4 sig, bytes memory args) = payload.callData.splitPayload();
    address newToken;
    /* not sure how to handle these unless "token" is exposed on curve as a public variable ...
    if (sig == ICurve.add_liquidity.selector) payload.liquidationSubmodule.delegateNotify(abi.encode(address(0x0)));
    else if (sig == ICurve.remove_liquidity.selector) {}
    */
    if (sig == ICurve.exchange.selector) {
      CurveAdapterLib.ExchangeInputs memory inputs = args.decodeExchangeInputs();
      require(ICurve(payload.to).coins(uint256(uint128(inputs.i))).approveForMaxIfNeeded(payload.to), "token approval failed");
      newToken = ICurve(payload.to).coins(uint256(uint128(inputs.j)));
    } else if (sig == ICurve.exchange_underlying.selector) {
      CurveAdapterLib.ExchangeInputs memory inputs = args.decodeExchangeInputs();
      require(ICurve(payload.to).underlying_coins(uint256(uint128(inputs.i))).approveForMaxIfNeeded(payload.to), "token approval failed");
      newToken = ICurve(payload.to).underlying_coins(uint256(uint128(inputs.j)));
    } else revert("unsupported contract call");
    if (newToken != address(0x0)) require(payload.liquidationSubmodule.delegateNotify(abi.encode(newToken)), "failed to notify liquidation module");
    (bool success, bytes memory retval) = payload.to.call{ gas: gasleft(), value: payload.value }(payload.callData);
    ModuleLib.bubbleResult(success, retval);
  }
}
