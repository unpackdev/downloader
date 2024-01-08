// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./ITokenAdapter.sol";
import "./FulcrumInterfaces.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./LowGasSafeMath.sol";
import "./TransferHelper.sol";
import "./MinimalSignedMath.sol";


contract FulcrumEtherAdapter is IEtherAdapter {
  using MinimalSignedMath for uint256;
  using LowGasSafeMath for uint256;
  using TransferHelper for address;

/* ========== Constants ========== */

  IBZX public constant bzx = IBZX(0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f);
  uint256 internal constant weiPercentPrecision = 1e20;

  address public override underlying;

  address public override token;

/* ========== Constructor & Initializer ========== */

  constructor(address _underlying, address _token) {
    underlying = _underlying;
    token = _token;
    _underlying.safeApproveMax(token);
  }

/* ========== Metadata ========== */

  string public override name = "Fulcrum ETH Adapter";

  function availableLiquidity() public view override returns (uint256) {
    (,,,uint256 interestUnPaid, uint256 interestFeePercent,) = bzx.getLenderInterestData(
      token,
      underlying
    );

    interestUnPaid = interestUnPaid
      .mul(weiPercentPrecision.sub(interestFeePercent))
      / weiPercentPrecision;
    return IERC20(underlying).balanceOf(token).add(interestUnPaid);
  }

/* ========== Conversion Queries ========== */

  function toUnderlyingAmount(uint256 tokenAmount) public view override returns (uint256) {
    return tokenAmount.mul(IToken(token).tokenPrice()) / uint256(1e18);
  }

  function toWrappedAmount(uint256 underlyingAmount) public view override returns (uint256) {
    return underlyingAmount.mul(1e18) / IToken(token).tokenPrice();
  }

/* ========== Performance Queries ========== */

  function getAPR() public view virtual override returns (uint256 apr) {
    return IToken(token).supplyInterestRate() / 100;
  }

  function getHypotheticalAPR(int256 liquidityDelta) external view virtual override returns (uint256 apr) {
    IToken iToken = IToken(token);
    return iToken.totalSupplyInterestRate(
      iToken.totalAssetSupply().add(liquidityDelta)
    ) / 100;
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
    assets = new address[](1);
    aprs = new uint256[](1);
    assets[0] = underlying;
    aprs[0] = getAPR();
  }

/* ========== Caller Balance Queries ========== */

  function balanceWrapped() external view virtual override returns (uint256) {
    return IERC20(token).balanceOf(msg.sender);
  }

  function balanceUnderlying() external view virtual override returns (uint256) {
    return IToken(token).assetBalanceOf(msg.sender);
  }

/* ========== Token Actions ========== */

  function deposit(uint256 amountUnderlying) external virtual override returns (uint256 amountMinted) {
    underlying.safeTransferFrom(msg.sender, address(this), amountUnderlying);
    amountMinted = IToken(token).mint(msg.sender, amountUnderlying);
    require(amountMinted > 0, "IToken: Mint failed");
  }

  function depositETH() external payable virtual override returns (uint256 amountMinted) {
    amountMinted = IToken(token).mintWithEther{value: msg.value}(msg.sender);
    require(amountMinted > 0, "IToken: Mint failed");
  }

  function withdraw(uint256 amountToken) external virtual override returns (uint256 amountReceived) {
    token.safeTransferFrom(msg.sender, address(this), amountToken);
    amountReceived = IToken(token).burn(msg.sender, amountToken);
    require(amountReceived > 0, "IToken: Burn failed");
  }

  function withdrawAsETH(uint256 amountToken) external virtual override returns (uint256 amountReceived) {
    token.safeTransferFrom(msg.sender, address(this), amountToken);
    amountReceived = IToken(token).burnToEther(msg.sender, amountToken);
    require(amountReceived > 0, "IToken: Burn failed");
  }

  function withdrawAll() external virtual override returns (uint256 amountReceived) {
    uint256 amountToken = IERC20(token).balanceOf(msg.sender);
    token.safeTransferFrom(msg.sender, address(this), amountToken);
    amountReceived = IToken(token).burn(msg.sender, amountToken);
    require(amountReceived > 0, "IToken: Burn failed");
  }

  function withdrawAllAsETH() external virtual override returns (uint256 amountReceived) {
    uint256 amountToken = IERC20(token).balanceOf(msg.sender);
    token.safeTransferFrom(msg.sender, address(this), amountToken);
    amountReceived = IToken(token).burnToEther(msg.sender, amountToken);
    require(amountReceived > 0, "IToken: Burn failed");
  }

  function withdrawUnderlying(uint256 amountUnderlying) external virtual override returns (uint256 amountBurned) {
    amountBurned = amountUnderlying.mul(1e18).divCeil(IToken(token).tokenPrice());
    token.safeTransferFrom(msg.sender, address(this), amountBurned);
    require(IToken(token).burn(msg.sender, amountBurned) > 0, "IToken: Burn failed");
  }

  function withdrawUnderlyingAsETH(uint256 amountUnderlying) external virtual override returns (uint256 amountBurned) {
    amountBurned = amountUnderlying.mul(1e18).divCeil(IToken(token).tokenPrice());
    token.safeTransferFrom(msg.sender, address(this), amountBurned);
    require(IToken(token).burnToEther(msg.sender, amountBurned) > 0, "IToken: Burn failed");
  }

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external virtual override returns (uint256 amountReceived) {
    uint256 amountAvailable = availableLiquidity();
    amountReceived = amountAvailable < amountUnderlying ? amountAvailable : amountUnderlying;
    uint256 amountBurned = amountReceived.mul(1e18) / IToken(token).tokenPrice();
    token.safeTransferFrom(msg.sender, address(this), amountBurned);
    require(IToken(token).burn(msg.sender, amountBurned) > 0, "IToken: Burn failed");
  }
}