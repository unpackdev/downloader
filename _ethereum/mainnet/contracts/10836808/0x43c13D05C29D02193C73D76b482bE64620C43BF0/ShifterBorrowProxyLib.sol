pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IInitializationActionsReceiver.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";
import "./BorrowProxy.sol";
import "./BorrowProxyLib.sol";
import "./TokenUtils.sol";
import "./RevertCaptureLib.sol";
import "./SandboxLib.sol";
import "./IShifter.sol";
import "./IShifterERC20.sol";

library ShifterBorrowProxyLib {
  using SafeMath for *;
  using TokenUtils for *;
  struct ProxyRecord {
    LiquidityRequest request;
    LenderRecord loan;
    uint256 expected;
  }
  struct LiquidityRequest {
    address payable borrower;
    address token;
    bytes32 nonce;
    uint256 amount;
    bool forbidLoan;
    InitializationAction[] actions;
  }
  struct InitializationAction {
    address to;
    bytes txData;
  }
  event BorrowProxyInitialization(address indexed proxyAddress, SandboxLib.ProtectedExecution[]);
  function emitBorrowProxyInitialization(address /* proxyAddress */, SandboxLib.ProtectedExecution[] memory /* trace */) internal {
//    emit BorrowProxyInitialization(proxyAddress, trace);
  }
    
  function encodeProxyRecord(ProxyRecord memory record) internal pure returns (bytes memory result) {
    result = abi.encode(record);
  }
  function decodeProxyRecord(bytes memory record) internal pure returns (ProxyRecord memory result) {
    (result) = abi.decode(record, (ProxyRecord));
  }
  struct LiquidityRequestParcel {
    LiquidityRequest request;
    uint256 gasRequested;
    bytes signature;
  }
  function computeDepositAddress(LiquidityRequestParcel memory /* parcel */, address /* mpkh */, bool /* btcTestnet */) internal pure returns (string memory result) {
    result = "";
  }
  struct LenderParams {
    uint256 timeoutExpiry;
    uint256 bond;
    uint256 poolFee;
    uint256 keeperFee;
  }
  struct LenderRecord {
    address keeper;
    LenderParams params;
  }
  event ShifterBorrowProxyRepaid(address indexed user, ProxyRecord record);
  function emitShifterBorrowProxyRepaid(address user, ProxyRecord memory record) internal {
    emit ShifterBorrowProxyRepaid(user, record);
  }
  function encodeBorrowerMessage(LiquidityRequest memory params, bytes memory parcelActionsEncoded) internal pure returns (bytes memory result) {
    result = abi.encodePacked(params.borrower, params.token, params.nonce, params.amount, params.forbidLoan, parcelActionsEncoded);
  }
  function computeBorrowerSalt(LiquidityRequest memory params) internal pure returns (bytes32 result) {
    result = keccak256(computeBorrowerSaltPreimage(params));
  }
  function computeBorrowerSaltPreimage(LiquidityRequest memory params) internal pure returns (bytes memory result) {
    bytes memory parcelActionsEncoded = encodeParcelActions(params.actions);
    result = encodeBorrowerMessage(params, parcelActionsEncoded);
  }
  function encodeParcelActions(InitializationAction[] memory actions) internal pure returns (bytes memory retval) {
    retval = abi.encode(actions);
  }
  function computeLiquidityRequestParcelMessage(LiquidityRequestParcel memory parcel, bytes memory parcelActionsEncoded) internal view returns (bytes memory retval) {
    retval = abi.encodePacked(address(this), parcel.request.token, parcel.request.nonce, parcel.request.amount, parcel.gasRequested, parcel.request.forbidLoan, parcelActionsEncoded);
  }
  function computeLiquidityRequestPreimage(LiquidityRequestParcel memory parcel) internal view returns (bytes memory result) {
    bytes memory parcelActionsEncoded = encodeParcelActions(parcel.request.actions);
    result = computeLiquidityRequestParcelMessage(parcel, parcelActionsEncoded);
  }
  function computeLiquidityRequestHash(LiquidityRequestParcel memory parcel) internal view returns (bytes32 result) {
    result = keccak256(computeLiquidityRequestPreimage(parcel));
  }
  function validateSignature(LiquidityRequestParcel memory parcel, bytes32 hash) internal pure returns (bool) {
    return parcel.request.borrower == ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), parcel.signature);
  }
  function validateSignature(LiquidityRequestParcel memory parcel) internal view returns (bool) {
    return parcel.request.borrower == ECDSA.recover(ECDSA.toEthSignedMessageHash(computeLiquidityRequestHash(parcel)), parcel.signature);
  }
  struct ShiftParameters {
    bytes32 txhash;
    uint256 vout;
    bytes32 pHash;
    uint256 amount;
    bytes darknodeSignature;
  }
  struct TriggerParcel {
    ProxyRecord record;
    ShiftParameters shiftParameters;
  }
  struct SansBorrowShiftParcel {
    LiquidityRequestParcel liquidityRequestParcel;
    ShiftParameters shiftParameters;
    InitializationAction[] actions;
  }
  function decodeTriggerParcel(bytes memory parcel) internal pure returns (TriggerParcel memory result) {
    (result) = abi.decode(parcel, (TriggerParcel));
  }
  function encodeNPreimage(TriggerParcel memory parcel) internal pure returns (bytes memory result) {
    result = abi.encodePacked(parcel.record.request.nonce, parcel.shiftParameters.txhash, parcel.shiftParameters.vout);
  }
  function computeNHash(TriggerParcel memory parcel) internal pure returns (bytes32) {
    return keccak256(encodeNPreimage(parcel));
  }
  uint256 constant BIPS_DENOMINATOR = 10000;
  function computeExpectedAmount(uint256 amount, address shifter, address token) internal returns (uint256 expected) {
    uint256 mintFee = getMintFee(shifter);
    uint256 underlyingAmount = getUnderlyingAmount(token, amount);
    uint256 fee = underlyingAmount.mul(mintFee).div(BIPS_DENOMINATOR);
    expected = underlyingAmount.sub(fee);
  }
  function getMintFee(address shifter) internal view returns (uint256 mintFee) {
    mintFee = uint256(IShifter(shifter).mintFee());
  }
  function getUnderlyingAmount(address token, uint256 amount) internal returns (uint256 underlyingAmount) {
    underlyingAmount = IShifterERC20(token).fromUnderlying(amount);
  }
  function computePostFee(ProxyRecord memory record) internal pure returns (uint256) {
    return record.expected.sub(computePoolFee(record).add(computeKeeperFee(record)));
  }
  function computePoolFee(ProxyRecord memory record) internal pure returns (uint256) {
    return record.expected.mul(record.loan.params.poolFee).div(uint256(1 ether));
  }
  function computeKeeperFee(ProxyRecord memory record) internal pure returns (uint256) {
    return record.expected.mul(record.loan.params.keeperFee).div(uint256(1 ether));
  }
  function computeAdjustedKeeperFee(ProxyRecord memory record, uint256 actual) internal pure returns (uint256) {
    return actual.mul(record.loan.params.keeperFee).div(uint256(1 ether));
  }
}
