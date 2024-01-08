// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./AbstractEtherAdapter.sol";
import "./AaveV1Interfaces.sol";
import "./IWETH.sol";
import "./IERC20.sol";
import "./LowGasSafeMath.sol";
import "./TransferHelper.sol";
import "./MinimalSignedMath.sol";
import "./RayDiv.sol";


contract AaveV1EtherAdapter is AbstractEtherAdapter {
  using MinimalSignedMath for uint256;
  using LowGasSafeMath for uint256;
  using RayDiv for uint256;
  using TransferHelper for address;

/* ========== Constants ========== */

  address public constant ETH_RESERVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

/* ========== Constants ========== */

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
    return address(core).balance;
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
    apr = core.getReserveCurrentLiquidityRate(ETH_RESERVE_ADDRESS) / 1e9;
  }

  function getHypotheticalAPR(int256 liquidityDelta) external view virtual override returns (uint256 apr) {
    (uint256 liquidityRate,,) = core.getReserveInterestRateStrategyAddress(ETH_RESERVE_ADDRESS).calculateInterestRates(
      ETH_RESERVE_ADDRESS,
      core.getReserveAvailableLiquidity(ETH_RESERVE_ADDRESS).add(liquidityDelta),
      core.getReserveTotalBorrowsStable(ETH_RESERVE_ADDRESS),
      core.getReserveTotalBorrowsVariable(ETH_RESERVE_ADDRESS),
      core.getReserveCurrentAverageStableBorrowRate(ETH_RESERVE_ADDRESS)
    );
    return liquidityRate / 1e9;
  }

/* ========== Caller Balance Queries ========== */

  function balanceUnderlying() external view virtual override returns (uint256) {
    return IERC20(token).balanceOf(msg.sender);
  }

/* ========== Internal Ether Handlers ========== */
  
  // Convert to WETH if contract takes WETH
  function _afterReceiveETH(uint256 amount) internal virtual override {}

  // Convert to WETH if contract takes ETH
  function _afterReceiveWETH(uint256 amount) internal virtual override {
    IWETH(underlying).withdraw(amount);
  }

  // Convert to ETH if contract returns WETH
  function _beforeSendETH(uint256 amount) internal virtual override {}

  // Convert to WETH if contract returns ETH
  function _beforeSendWETH(uint256 amount) internal virtual override {
    IWETH(underlying).deposit{value: amount}();
  }

/* ========== Internal Actions ========== */

  function _approve() internal virtual override {}

  function _mint(uint256 amountUnderlying) internal virtual override returns (uint256 amountMinted) {
    amountMinted = amountUnderlying;
    pool.deposit{value: amountUnderlying}(ETH_RESERVE_ADDRESS, amountUnderlying, 0);
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