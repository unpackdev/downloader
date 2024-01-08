// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./AbstractErc20Adapter.sol";
import "./CompoundInterfaces.sol";
import "./IERC20.sol";
import "./IWETH.sol";
import "./LowGasSafeMath.sol";
import "./TransferHelper.sol";
import "./MinimalSignedMath.sol";
import "./CTokenParams.sol";


contract CrErc20Adapter is AbstractErc20Adapter() {
  using MinimalSignedMath for uint256;
  using LowGasSafeMath for uint256;
  using TransferHelper for address;

/* ========== Internal Queries ========== */

  function _protocolName() internal view virtual override returns (string memory) {
    return "Cream";
  }

/* ========== Metadata ========== */

  function availableLiquidity() public view override returns (uint256) {
    return IERC20(underlying).balanceOf(token);
  }

/* ========== Conversion Queries ========== */

  function toUnderlyingAmount(uint256 tokenAmount) public view override returns (uint256) {
    return (
      tokenAmount
      .mul(CTokenParams.currentExchangeRate(token))
      / uint256(1e18)
    );
  }

  function toWrappedAmount(uint256 underlyingAmount) public view override returns (uint256) {
    return underlyingAmount
      .mul(1e18)
      / CTokenParams.currentExchangeRate(token);
  }

/* ========== Performance Queries ========== */

  function getAPR() public view virtual override returns (uint256) {
    return ICToken(token).supplyRatePerBlock().mul(2102400);
  }

  function getHypotheticalAPR(int256 liquidityDelta) external view virtual override returns (uint256) {
    ICToken cToken = ICToken(token);
    (
      address model,
      uint256 cashPrior,
      uint256 borrowsPrior,
      uint256 reservesPrior,
      uint256 reserveFactorMantissa
    ) = CTokenParams.getInterestRateParameters(address(cToken));
    return IInterestRateModel(model).getSupplyRate(
      cashPrior.add(liquidityDelta),
      borrowsPrior,
      reservesPrior,
      reserveFactorMantissa
    ).mul(2102400);
  }

/* ========== Caller Balance Queries ========== */

  function balanceUnderlying() external view virtual override returns (uint256) {
    return toUnderlyingAmount(ICToken(token).balanceOf(msg.sender));
  }

/* ========== Internal Actions ========== */

  function _approve() internal virtual override {
    underlying.safeApproveMax(token);
  }

  function _mint(uint256 amountUnderlying) internal virtual override returns (uint256 amountMinted) {
    address _token = token;
    require(ICToken(_token).mint(amountUnderlying) == 0, "CrErc20: Mint failed");
    amountMinted = IERC20(_token).balanceOf(address(this));
  }

  function _burn(uint256 amountToken) internal virtual override returns (uint256 amountReceived) {
    require(ICToken(token).redeem(amountToken) == 0, "CrErc20: Burn failed");
    amountReceived = IERC20(underlying).balanceOf(address(this));
  }

  function _burnUnderlying(uint256 amountUnderlying) internal virtual override returns (uint256 amountBurned) {
    amountBurned = toWrappedAmount(amountUnderlying);
    token.safeTransferFrom(msg.sender, address(this), amountBurned);
    require(ICToken(token).redeemUnderlying(amountUnderlying) == 0, "CrErc20: Burn failed");
  }
}