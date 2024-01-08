// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./AbstractErc20Adapter.sol";
import "./AaveV1Interfaces.sol";
import "./IERC20.sol";
import "./LowGasSafeMath.sol";
import "./TransferHelper.sol";
import "./MinimalSignedMath.sol";
import "./RayDiv.sol";


contract AaveV1Erc20Adapter is AbstractErc20Adapter {
  using MinimalSignedMath for uint256;
  using LowGasSafeMath for uint256;
  using RayDiv for uint256;
  using TransferHelper for address;

/* ========== Constants ========== */

  // ILendingPoolAddressesProvider public immutable aave;
  ILendingPool public immutable pool;
  ILendingPoolCore public immutable core;

/* ========== Constructor ========== */

  constructor(ILendingPoolAddressesProvider _aave) {
    pool = _aave.getLendingPool();
    core = _aave.getLendingPoolCore();
  }

/* ========== Internal Queries ========== */

  function _protocolName() internal view virtual override returns (string memory) {
    return "Aave V1";
  }

/* ========== Metadata ========== */

  function availableLiquidity() public view override returns (uint256) {
    return IERC20(underlying).balanceOf(address(core));
  }

/* ========== Conversion Queries ========== */

  function toUnderlyingAmount(uint256 tokenAmount) external view virtual override returns (uint256) {
    return tokenAmount;
  }

  function toWrappedAmount(uint256 underlyingAmount) external view virtual override returns (uint256) {
    return underlyingAmount;
  }

/* ========== Performance Queries ========== */

  function getAPR() public view virtual override returns (uint256 apr) {
    apr = core.getReserveCurrentLiquidityRate(underlying) / 1e9;
  }

  function getHypotheticalAPR(int256 liquidityDelta) external view virtual override returns (uint256 apr) {
    address reserve = underlying;
    (uint256 liquidityRate,,) = core.getReserveInterestRateStrategyAddress(reserve).calculateInterestRates(
      reserve,
      core.getReserveAvailableLiquidity(reserve).add(liquidityDelta),
      core.getReserveTotalBorrowsStable(reserve),
      core.getReserveTotalBorrowsVariable(reserve),
      core.getReserveCurrentAverageStableBorrowRate(reserve)
    );
    return liquidityRate / 1e9;
  }

/* ========== Caller Balance Queries ========== */

  function balanceUnderlying() external view virtual override returns (uint256) {
    return IERC20(token).balanceOf(msg.sender);
  }

/* ========== Internal Actions ========== */

  function _approve() internal virtual override {
    underlying.safeApproveMax(address(core));
  }

  function _mint(uint256 amountUnderlying) internal virtual override returns (uint256 amountMinted) {
    amountMinted = amountUnderlying;
    pool.deposit(underlying, amountUnderlying, 0);
  }

  function _burn(uint256 amountToken) internal virtual override returns (uint256 amountReceived) {
    amountReceived = amountToken;
    IAToken(token).redeem(amountToken);
  }

  function _burnUnderlying(uint256 amountUnderlying) internal virtual override returns (uint256 amountBurned) {
    token.safeTransferFrom(msg.sender, address(this), amountUnderlying);
    amountBurned = amountUnderlying;
    IAToken(token).redeem(amountUnderlying);
  }
}