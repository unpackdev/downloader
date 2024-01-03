pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./TokenUtils.sol";
import "./LiquidityToken.sol";
import "./IERC20.sol";
import "./SafeViewExecutor.sol";
import "./SandboxLib.sol";
import "./StringLib.sol";
import "./NullCloneConstructor.sol";
import "./BorrowProxy.sol";
import "./ShifterBorrowProxyLib.sol";
import "./ShifterPool.sol";
import "./IShifter.sol";
import "./Math.sol";

contract ShifterBorrowProxy is BorrowProxy, SafeViewExecutor, NullCloneConstructor {
  using ShifterBorrowProxyLib for *;
  using StringLib for *;
  using SandboxLib for *;
  using TokenUtils for *;
  uint256 constant MINIMUM_GAS_CONTINUE = 5e5;
  function getShifter(address token) internal view returns (IShifter shifter) {
    shifter = ShifterPool(isolate.masterAddress).getShifterHandler(token);
  }
  function mint(ShifterBorrowProxyLib.TriggerParcel memory parcel) internal returns (uint256 amount) {
    amount = getShifter(parcel.record.request.token).mint(parcel.shiftParameters.pHash, parcel.shiftParameters.amount, parcel.computeNHash(), parcel.shiftParameters.darknodeSignature);
  }
  function _getGasReserved() internal view returns (uint256 result) {
    result = ShifterPool(isolate.masterAddress).getGasReserved(address(this));
  }
  function _payoutCallbackGas(address payable borrower, uint256 amount, uint256 originAmount) internal {
    if (amount != 0) ShifterPool(isolate.masterAddress).payoutCallbackGas(borrower, amount - originAmount, originAmount);
  }
  function repayLoan(bytes memory data) public returns (bool) {
    uint256 startGas = gasleft();
    (bool success, ShifterBorrowProxyLib.ProxyRecord memory record, address payable pool, uint256 repayAmount) = _repayLoan(data);
    if (maybeRelayResolveLoan(success, record, pool, repayAmount)) {
      ShifterBorrowProxyLib.emitShifterBorrowProxyRepaid(record.request.borrower, record);
      uint256 amount = _getGasReserved();
      uint256 originAmount = Math.min((gasleft() - startGas + 20000)*tx.gasprice, amount); // another estimate
      _payoutCallbackGas(record.request.borrower, amount, originAmount);
      return true;
    } else return false;
  }
  function _repayLoan(bytes memory data) internal returns (bool success, ShifterBorrowProxyLib.ProxyRecord memory record, address payable pool, uint256 repayAmount) {
    (ShifterBorrowProxyLib.TriggerParcel memory parcel) = data.decodeTriggerParcel();
    record = parcel.record;
    parcel.record.request.actions = new ShifterBorrowProxyLib.InitializationAction[](0);
    require(validateProxyRecord(parcel.record.encodeProxyRecord()), "proxy record invalid");
    require(!isolate.isLiquidating, "proxy is being liquidated");
    uint256 fee = parcel.record.computeAdjustedKeeperFee(parcel.record.expected);
    pool = isolate.masterAddress;
    uint256 amount;
    if (!isolate.isRepaying) {
      isolate.isRepaying = true;
      isolate.actualizedShift = amount = mint(parcel);
    } else amount = isolate.actualizedShift;
    address[] memory set = isolate.repaymentSet.set;
    for (uint256 i = isolate.repaymentIndex; i < set.length; i++) {
      if (gasleft() < MINIMUM_GAS_CONTINUE || !set[i].delegateRepay()) {
        isolate.repaymentIndex = i;
        return (false, record, pool, 0);
      }
    }
    isolate.unbound = true;
    require(parcel.record.request.token.sendToken(parcel.record.loan.keeper, fee), "keeper payout failed");
    record.request.amount = amount;
    repayAmount = amount - fee;
    success = true;
  }
  function relayMint(address shifter, address token, bytes32 pHash, uint256 amount, bytes32 nHash, bytes memory darknodeSignature, uint256 fee) public returns (bool) {
    require(isolate.masterAddress == msg.sender, "must be called by shifter pool");
    IShifter(shifter).mint(pHash, amount, nHash, darknodeSignature);
    if (fee != 0) require(token.sendToken(msg.sender, fee), "failed to send token");
    isolate.unbound = true;
  }
  function getBalanceOf(address token, address user) internal view returns (uint256) {
    return IERC20(token).balanceOf(user);
  }
  function getLiquidityToken(address payable pool, address token) internal view returns (address liqToken) {
    liqToken = address(ShifterPool(pool).getLiquidityTokenHandler(token));
  }
  function maybeRelayResolveLoan(bool success, ShifterBorrowProxyLib.ProxyRecord memory record, address payable pool, uint256 repayPool) internal returns (bool) {
    if (success) {
      address liqToken = getLiquidityToken(pool, record.request.token);
      require(record.request.token.sendToken(pool, repayPool), "failed to approve pool for token transfer");
      require(ShifterPool(pool).relayResolveLoan(record.request.token, liqToken, record.loan.keeper, record.loan.params.bond, repayPool, record.expected), "loan resolution failure");
      return true;
    }
    return false;
  }
  function defaultLoan(bytes memory data) public {
    (bool success, ShifterBorrowProxyLib.ProxyRecord memory record, address payable pool, uint256 postBalance) = _defaultLoan(data);
    maybeRelayResolveLoan(success, record, pool, postBalance);
    _payoutCallbackGas(record.request.borrower, 0, _getGasReserved());
    selfdestruct(msg.sender);
  }
  function _defaultLoan(bytes memory data) internal returns (bool success, ShifterBorrowProxyLib.ProxyRecord memory record, address payable pool, uint256 postBalance) {
    require(!isolate.isRepaying, "loan being repaid");
    require(!isolate.unbound, "loan already repaid");
    require(validateProxyRecord(data), "proxy record invalid");
    record = data.decodeProxyRecord();
    address[] memory set = isolate.liquidationSet.set;
    if (record.loan.params.timeoutExpiry >= block.number) {
      isolate.isLiquidating = true;
      for (uint256 i = isolate.liquidationIndex; i < set.length; i++) {
        if (gasleft() < MINIMUM_GAS_CONTINUE || !set[i].delegateLiquidate()) {
          isolate.liquidationIndex = i;
          return (false, record, pool, postBalance);
        }
      }
      isolate.liquidationIndex = set.length;
      pool = isolate.masterAddress;
      postBalance = getBalanceOf(record.request.token, address(this));
      success = true;
    } else {
      success = false;
    }
  }
  function receiveInitializationActions(ShifterBorrowProxyLib.InitializationAction[] memory actions) public {
    require(msg.sender == address(isolate.masterAddress), "must be called from shifter pool");
    actions.processActions();
  }
  fallback() external payable override {}
  receive() external payable override {}
}
