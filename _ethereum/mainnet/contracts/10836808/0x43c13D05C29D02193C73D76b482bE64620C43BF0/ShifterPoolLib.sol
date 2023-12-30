pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ECDSA.sol";
import "./TokenUtils.sol";
import "./SafeMath.sol";
import "./BorrowProxyLib.sol";
import "./IShifter.sol";
import "./IShifterRegistry.sol";
import "./LiquidityToken.sol";
import "./ShifterBorrowProxy.sol";
import "./ShifterBorrowProxyLib.sol";
import "./ShifterBorrowProxyFactoryLib.sol";
import "./FactoryLib.sol";
import "./ShifterPool.sol";
import "./AssetForwarderLib.sol";

library ShifterPoolLib {
  using BorrowProxyLib for *;
  using TokenUtils for *;
  using ShifterBorrowProxyLib for *;
  using ShifterBorrowProxyFactoryLib for *;
  using SafeMath for *;
  struct SetupParams {
    address shifterRegistry;
    uint256 minTimeout;
    uint256 poolFee;
    uint256 daoFee;
    uint256 maxLoan;
    uint256 gasEstimate;
    uint256 maxGasPriceForRefund;
  }
  struct BorrowState {
    uint256 startGas;
    uint256 gasPrice;
    uint256 refundAmount;
  }
  struct Isolate {
    uint256 genesis;
    address borrowProxyImplementation;
    address assetForwarderImplementation;
    address shifterRegistry;
    uint256 minTimeout;
    uint256 poolFee;
    uint256 daoFee;
    uint256 maxLoan;
    uint256 gasEstimate;
    uint256 maxGasPriceForRefund;
    mapping (address => uint256) gasReserved;
    mapping (address => bool) isKeeper;
    mapping (bytes32 => bool) provisionExecuted;
    mapping (address => address) tokenToLiquidityToken;
    mapping (address => uint256) tokenToBaseFee;
    BorrowProxyLib.ControllerIsolate borrowProxyController;
    BorrowProxyLib.ModuleRegistry registry;
  }
  function splitForDAO(uint256 actualAmount, uint256 daoFee) internal pure returns (uint256 amount, uint256 daoAmount) {
    daoAmount = actualAmount.mul(uint256(daoFee)).div(uint256(1 ether));
    if (daoAmount < actualAmount) {
      amount = actualAmount - daoAmount;
    } else daoAmount = actualAmount;
  }
  function deployAssetForwarder(BorrowProxyLib.ProxyIsolate storage isolate, bytes32 salt) internal returns (address created) {
    return ShifterPool(isolate.masterAddress).deployAssetForwarderClone(salt);
  }
  function sendMint(address proxyAddress, address shifter, ShifterBorrowProxyLib.SansBorrowShiftParcel memory parcel, bytes32 nHash, uint256 fee) internal {
    ShifterBorrowProxy(address(uint160(proxyAddress))).relayMint(shifter, parcel.liquidityRequestParcel.request.token, parcel.shiftParameters.pHash, parcel.shiftParameters.amount, nHash, parcel.shiftParameters.darknodeSignature, fee);
  }
  function makeBorrowProxy(Isolate storage isolate, bytes32 salt) internal returns (address payable proxyAddress) {
    proxyAddress = address(uint160(isolate.deployBorrowProxy(salt)));
  }
  function issueLoan(Isolate storage isolate, address token, address payable proxyAddress, uint256 fee, uint256 getGas) internal {
    require(LiquidityToken(getLiquidityToken(isolate, token)).loan(proxyAddress, fee, getGas), "insufficient funds in liquidity pool");
  }
  function setupBorrowProxy(address payable proxyAddress, address borrower, address token, bool unbound) internal {
    require(ShifterBorrowProxy(proxyAddress).setup(borrower, token, unbound), "setup phase failure");
  }
  function sendInitializationActions(address payable proxyAddress, ShifterBorrowProxyLib.InitializationAction[] memory actions) internal {
    ShifterBorrowProxy(proxyAddress).receiveInitializationActions(actions);
  }
  function computeLoanParams(Isolate storage isolate, uint256 amount, uint256 bond, uint256 timeoutExpiry) internal view returns (ShifterBorrowProxyLib.LenderParams memory) {
    require(timeoutExpiry >= isolate.minTimeout, "timeout insufficient");
    uint256 baseKeeperFee = uint256(1 ether).div(100); // 1%
    require(bond.mul(uint256(1 ether)).div(amount) > uint256(1 ether).div(100), "bond below minimum");
    uint256 keeperFee = amount < bond ? baseKeeperFee : uint256(baseKeeperFee).mul(bond).div(amount);
    return ShifterBorrowProxyLib.LenderParams({
      keeperFee: keeperFee,
      poolFee: isolate.poolFee,
      timeoutExpiry: block.number + timeoutExpiry,
      bond: bond
    });
  }
  struct LiquidityProvisionMessage {
    uint256 amount;
    uint256 nonce;
    uint256 keeperFee;
    uint256 timeoutExpiry;
    bytes signature;
  }
  struct LiquidityTokenLaunch {
    address token;
    address liqToken;
    uint256 baseFee;
  }
  function launchLiquidityToken(Isolate storage isolate, address weth, address router, address token, string memory name, string memory symbol, uint8 decimals) internal returns (address) {
    require(isolate.tokenToLiquidityToken[token] == address(0x0), "already deployed liquidity token for target token");
    address liquidityToken = address(new LiquidityToken(weth, router, address(uint160(address(this))), token, name, symbol, decimals));
    isolate.tokenToLiquidityToken[token] = liquidityToken;
    return liquidityToken;
  }
  function getLiquidityToken(Isolate storage isolate, address token) internal view returns (address) {
    address retval = isolate.tokenToLiquidityToken[token];
    require(retval != address(0x0), "not a registered liquidity token");
    return retval;
  }
  function lendLiquidity(Isolate storage isolate, address provider, address token, address target, uint256 amount) internal returns (bool) {
    if (!isolate.isKeeper[provider]) return false;
    return token.transferTokenFrom(provider, target, amount);
  }
  function getShifter(Isolate storage isolate, address token) internal view returns (IShifter) {
    return IShifterRegistry(isolate.shifterRegistry).getGatewayByToken(token);
  }
  function provisionHashAlreadyUsed(Isolate storage isolate, bytes32 provisionHash) internal view returns (bool) {
    return isolate.provisionExecuted[provisionHash];
  }
  function preventProvisionReplay(Isolate storage isolate, bytes32 provisionHash) internal returns (bool) {
    isolate.provisionExecuted[provisionHash] = true;
    return true;
  }
  function mapBorrowProxy(Isolate storage isolate, address proxyAddress, ShifterBorrowProxyLib.ProxyRecord memory record) internal {
    bytes memory data = record.encodeProxyRecord();
    isolate.borrowProxyController.setProxyToken(proxyAddress, record.request.token);
    isolate.borrowProxyController.setProxyOwner(proxyAddress, record.request.borrower);
    record.request.borrower.transfer(msg.value);
    isolate.borrowProxyController.mapProxyRecord(proxyAddress, data);
    BorrowProxyLib.emitBorrowProxyMade(record.request.borrower, proxyAddress, data);
  }
}   
