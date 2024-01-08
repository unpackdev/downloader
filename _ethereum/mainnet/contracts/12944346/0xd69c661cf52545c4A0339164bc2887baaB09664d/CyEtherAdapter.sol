// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./AbstractEtherAdapter.sol";
import "./CompoundInterfaces.sol";
import "./IERC20.sol";
import "./IWETH.sol";
import "./LowGasSafeMath.sol";
import "./TransferHelper.sol";
import "./MinimalSignedMath.sol";
import "./CyTokenParams.sol";


contract CyEtherAdapter is AbstractEtherAdapter() {
  using MinimalSignedMath for uint256;
  using LowGasSafeMath for uint256;
  using TransferHelper for address;

/* ========== Internal Queries ========== */

  function _protocolName() internal view virtual override returns (string memory) {
    return "IronBank";
  }

/* ========== Metadata ========== */

  function availableLiquidity() public view override returns (uint256) {
    return IERC20(underlying).balanceOf(token);
  }

/* ========== Conversion Queries ========== */

  function toUnderlyingAmount(uint256 tokenAmount) public view override returns (uint256) {
    return (
      tokenAmount
      .mul(CyTokenParams.currentExchangeRate(token))
      / uint256(1e18)
    );
  }

  function toWrappedAmount(uint256 underlyingAmount) public view override returns (uint256) {
    return underlyingAmount
      .mul(1e18)
      / CyTokenParams.currentExchangeRate(token);
  }

/* ========== Performance Queries ========== */

  function getAPR() public view virtual override returns (uint256) {
    return CyTokenParams.getSupplyRate(token, 0);
  }

  function getHypotheticalAPR(int256 liquidityDelta) external view virtual override returns (uint256) {
    return CyTokenParams.getSupplyRate(token, liquidityDelta);
  }

/* ========== Caller Balance Queries ========== */

  function balanceUnderlying() external view virtual override returns (uint256) {
    return toUnderlyingAmount(ICToken(token).balanceOf(msg.sender));
  }

/* ========== Internal Ether Handlers ========== */
  
  // Convert to WETH if contract takes WETH
  function _afterReceiveETH(uint256 amount) internal virtual override {
    IWETH(underlying).deposit{value: amount}();
  }

  // Convert to ETH if contract takes ETH
  function _afterReceiveWETH(uint256 amount) internal virtual override {}

  // Convert to ETH if contract returns WETH
  function _beforeSendETH(uint256 amount) internal virtual override {
    IWETH(underlying).withdraw(amount);
  }

  // Convert to WETH if contract returns ETH
  function _beforeSendWETH(uint256 amount) internal virtual override {}

/* ========== Internal Actions ========== */

  function _approve() internal virtual override {
    underlying.safeApproveMax(token);
  }

  function _mint(uint256 amountUnderlying) internal virtual override returns (uint256 amountMinted) {
    address _token = token;
    require(ICToken(_token).mint(amountUnderlying) == 0, "CErc20: Mint failed");
    amountMinted = IERC20(_token).balanceOf(address(this));
  }

  function _burn(uint256 amountToken) internal virtual override returns (uint256 amountReceived) {
    require(ICToken(token).redeem(amountToken) == 0, "CErc20: Burn failed");
    amountReceived = IERC20(underlying).balanceOf(address(this));
  }

  function _burnUnderlying(uint256 amountUnderlying) internal virtual override returns (uint256 amountBurned) {
    amountBurned = toWrappedAmount(amountUnderlying);
    token.safeTransferFrom(msg.sender, address(this), amountBurned);
    require(ICToken(token).redeemUnderlying(amountUnderlying) == 0, "CrErc20: Burn failed");
  }
}