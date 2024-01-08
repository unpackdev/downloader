// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./AbstractEtherAdapter.sol";
import "./CompoundInterfaces.sol";
import "./IERC20.sol";
import "./IWETH.sol";
import "./LowGasSafeMath.sol";
import "./TransferHelper.sol";
import "./MinimalSignedMath.sol";
import "./C1TokenParams.sol";


contract CEtherAdapter is AbstractEtherAdapter() {
  using MinimalSignedMath for uint256;
  using LowGasSafeMath for uint256;
  using TransferHelper for address;

/* ========== Constants ========== */

  IComptroller internal comptroller = IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
  address internal constant cComp = 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4;
  address internal constant comp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

/* ========== Internal Queries ========== */

  function _protocolName() internal view virtual override returns (string memory) {
    return "Compound";
  }

/* ========== Metadata ========== */

  function availableLiquidity() public view override returns (uint256) {
    return address(token).balance;
  }

/* ========== Conversion Queries ========== */

  function toUnderlyingAmount(uint256 tokenAmount) public view override returns (uint256) {
    return (
      tokenAmount
      .mul(C1TokenParams.currentExchangeRate(token))
      / uint256(1e18)
    );
  }

  function toWrappedAmount(uint256 underlyingAmount) public view override returns (uint256) {
    return underlyingAmount
      .mul(1e18)
      / C1TokenParams.currentExchangeRate(token);
  }

/* ========== Performance Queries ========== */

  function getRewardsAPR(
    ICToken cToken,
    uint256 _totalLiquidity
  ) internal view returns (uint256) {
    IPriceOracle oracle = comptroller.oracle();
    uint256 compPrice = oracle.getUnderlyingPrice(cComp);
    uint256 tokenPrice = oracle.getUnderlyingPrice(address(cToken));
    if (compPrice == 0 || tokenPrice == 0) return 0;
    uint256 annualRewards = comptroller.compSpeeds(address(cToken)).mul(2102400).mul(compPrice);
    return annualRewards.mul(1e18) / _totalLiquidity.mul(tokenPrice);
  }

  function getRewardsAPR() public view returns (uint256) {
    ICToken cToken = ICToken(token);
    (
      ,uint256 cash,
      uint256 borrows,
      uint256 reserves,
    ) = C1TokenParams.getInterestRateParametersV1(address(cToken));

    uint256 totalLiquidity = cash.add(borrows).sub(reserves);
    cToken.getCash().add(cToken.totalBorrows()).sub(cToken.totalReserves());
    return getRewardsAPR(ICToken(token), totalLiquidity);
  }

  function getAPR() public view virtual override returns (uint256) {
    ICToken cToken = ICToken(token);
    (
      address model,
      uint256 cashPrior,
      uint256 borrowsPrior,
      uint256 reservesPrior,
      uint256 reserveFactorMantissa
    ) = C1TokenParams.getInterestRateParametersV1(address(cToken));
    uint256 liquidityTotal = cashPrior.add(borrowsPrior).sub(reservesPrior);
    uint256 baseAPR = C1TokenParams.computeSupplyRateV1(
      model,
      cashPrior,
      borrowsPrior,
      reservesPrior,
      reserveFactorMantissa,
      0
    );
    uint256 rewardsAPR = getRewardsAPR(cToken, liquidityTotal);
    return baseAPR.add(rewardsAPR);
  }

  function getHypotheticalAPR(int256 liquidityDelta) external view virtual override returns (uint256) {
    ICToken cToken = ICToken(token);
    (
      address model,
      uint256 cashPrior,
      uint256 borrowsPrior,
      uint256 reservesPrior,
      uint256 reserveFactorMantissa
    ) = C1TokenParams.getInterestRateParametersV1(address(cToken));
    uint256 liquidityTotal = cashPrior.add(borrowsPrior).sub(reservesPrior);
    uint256 baseAPR = C1TokenParams.computeSupplyRateV1(
      model,
      cashPrior,
      borrowsPrior,
      reservesPrior,
      reserveFactorMantissa,
      liquidityDelta
    );
    uint256 rewardsAPR = getRewardsAPR(cToken, liquidityTotal.add(liquidityDelta));
    return baseAPR.add(rewardsAPR);
  }

  function getRevenueBreakdown()
    external
    view
    override
    returns (
      address[] memory assets,
      uint256[] memory aprs
    )
  {
    ICToken cToken = ICToken(token);
    (
      address model,
      uint256 cashPrior,
      uint256 borrowsPrior,
      uint256 reservesPrior,
      uint256 reserveFactorMantissa
    ) = C1TokenParams.getInterestRateParametersV1(address(cToken));
    uint256 liquidityTotal = cashPrior.add(borrowsPrior).sub(reservesPrior);
    uint256 baseAPR = C1TokenParams.computeSupplyRateV1(
      model,
      cashPrior,
      borrowsPrior,
      reservesPrior,
      reserveFactorMantissa,
      0
    );
    uint256 rewardsAPR = getRewardsAPR(cToken, liquidityTotal);
    uint256 size = rewardsAPR > 0 ? 2 : 1;
    assets = new address[](size);
    aprs = new uint256[](size);
    assets[0] = underlying;
    aprs[0] = baseAPR;
    if (rewardsAPR > 0) {
      assets[1] = comp;
      aprs[1] = rewardsAPR;
    }
  }

/* ========== Caller Balance Queries ========== */

  function balanceUnderlying() external view virtual override returns (uint256) {
    return toUnderlyingAmount(ICToken(token).balanceOf(msg.sender));
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

  function _claimRewardsIfAny(address account) internal {
    address[] memory holders = new address[](1);
    address[] memory cTokens = new address[](1);
    holders[0] = account;
    cTokens[0] = token;
    comptroller.claimComp(holders, cTokens, false, true);
  }

  function _approve() internal virtual override {}

  function _mint(uint256 amountUnderlying) internal virtual override returns (uint256 amountMinted) {
    address _token = token;
    ICToken(_token).mint{value: amountUnderlying}();
    amountMinted = IERC20(_token).balanceOf(address(this));
  }

  function _burn(uint256 amountToken) internal virtual override returns (uint256 amountReceived) {
    require(ICToken(token).redeem(amountToken) == 0, "CEther: Burn failed");
    amountReceived = address(this).balance;
    _claimRewardsIfAny(msg.sender);
  }

  function _burnUnderlying(uint256 amountUnderlying) internal virtual override returns (uint256 amountBurned) {
    amountBurned = toWrappedAmount(amountUnderlying);
    token.safeTransferFrom(msg.sender, address(this), amountBurned);
    require(ICToken(token).redeemUnderlying(amountUnderlying) == 0, "CErc20: Burn failed");
    _claimRewardsIfAny(msg.sender);
  }
}