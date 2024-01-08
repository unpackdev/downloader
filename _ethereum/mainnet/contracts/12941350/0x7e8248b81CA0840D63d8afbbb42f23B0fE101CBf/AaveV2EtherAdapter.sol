// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./AaveV2Erc20Adapter.sol";
import "./IWETH.sol";


contract AaveV2EtherAdapter is IEtherAdapter {
  using MinimalSignedMath for uint256;
  using LowGasSafeMath for uint256;
  using RayMul for uint256;
  using SymbolHelper for address;
  using TransferHelper for address;
  using TransferHelper for address payable;

/* ========== Constants ========== */

  ILendingPoolAddressesProvider public immutable addressesProvider;
  address public constant aave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  IAaveDistributionManager internal constant distributor = IAaveDistributionManager(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);
  ILendingPool public immutable pool;
  address public immutable userModuleImplementation;
  address public immutable override underlying;
  address public immutable override token;

/* ========== Storage ========== */
  mapping(address => address) public userModules;

/* ========== Fallbacks ========== */

  receive() external payable { return; }

/* ========== Constructor & Initializer ========== */

  constructor(
    ILendingPoolAddressesProvider _addressesProvider,
    address _underlying,
    address _token
  ) {
    addressesProvider = _addressesProvider;
    pool = _addressesProvider.getLendingPool();
    underlying = _underlying;
    token = _token;
    userModuleImplementation = address(new AaveV2UserModule(
      _addressesProvider,
      _underlying,
      _token
    ));
  }

/* ========== Metadata ========== */

  function name() external view virtual override returns (string memory) {
    return string(abi.encodePacked(
      "Aave V2 ",
      bytes(underlying.getSymbol()),
      " Adapter"
    ));
  }

/* ========== Metadata ========== */

  function availableLiquidity() public view override returns (uint256) {
    return IERC20(underlying).balanceOf(token);
  }

/* ========== Conversion Queries ========== */

  function toUnderlyingAmount(uint256 tokenAmount) public pure override returns (uint256) {
    return tokenAmount;
  }

  function toWrappedAmount(uint256 underlyingAmount) public pure override returns (uint256) {
    return underlyingAmount;
  }

/* ========== User Modules ========== */

  function getOrCreateUserModule() internal returns (AaveV2UserModule) {
    address module = userModules[msg.sender];
    if (module == address(0)) {
      module = (userModules[msg.sender] = CloneLibrary.createClone(userModuleImplementation));
      AaveV2UserModule(payable(module)).initialize(msg.sender);
    }
    return AaveV2UserModule(payable(module));
  }

/* ========== Performance Queries ========== */

  function getRewardsAPR(uint256 _totalLiquidity) internal view returns (uint256) {
    address _token = token;
    (, uint256 emissionsPerSecond,) = distributor.getAssetData(_token);
    if (emissionsPerSecond == 0) return 0;
    IPriceOracle oracle = addressesProvider.getPriceOracle();
    uint256 aavePrice = oracle.getAssetPrice(aave);
    uint256 underlyingPrice = oracle.getAssetPrice(underlying);
    if (aavePrice == 0 || underlyingPrice == 0) {
      return 0;
    }
    return aavePrice.mul(emissionsPerSecond.mul(365 days)).mul(1e18) / underlyingPrice.mul(_totalLiquidity);
  }

  function getRewardsAPR() external view returns (uint256) {
    return getRewardsAPR(IERC20(token).totalSupply());
  }

  function getBaseAPR() internal view returns (uint256) {
    ILendingPool.ReserveData memory reserve = pool.getReserveData(underlying);
    return uint256(reserve.currentLiquidityRate) / 1e9;
  }

  function getAPR() public view virtual override returns (uint256 apr) {
    return getBaseAPR().add(getRewardsAPR(IERC20(token).totalSupply()));
  }

  function getHypotheticalAPR(int256 liquidityDelta) external view virtual override returns (uint256 apr) {
    address reserve = underlying;
    ILendingPool.ReserveData memory data = pool.getReserveData(reserve);
    uint256 _availableLiquidity = IERC20(reserve).balanceOf(data.aTokenAddress).add(liquidityDelta);
    uint256 totalVariableDebt = data.variableDebtToken.scaledTotalSupply().rayMul(data.variableBorrowIndex);
    (uint256 totalStableDebt, uint256 avgStableRate) = data.stableDebtToken.getTotalSupplyAndAvgRate();
    (uint256 liquidityRate, ,) = data.interestRateStrategy.calculateInterestRates(
      reserve,
      _availableLiquidity,
      totalStableDebt,
      totalVariableDebt,
      avgStableRate,
      ReserveConfigurationLib.getReserveFactor(data.configuration)
    );
    uint256 newLiquidity = _availableLiquidity.add(totalVariableDebt).add(totalStableDebt);
    return (liquidityRate / 1e9).add(getRewardsAPR(newLiquidity));
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
    uint256 rewardsAPR = getRewardsAPR(IERC20(token).totalSupply());
    uint256 size = rewardsAPR > 0 ? 2 : 1;
    assets = new address[](size);
    aprs = new uint256[](size);
    assets[0] = underlying;
    aprs[0] = getBaseAPR();
    if (rewardsAPR > 0) {
      assets[1] = aave;
      aprs[1] = rewardsAPR;
    }
  }

/* ========== Caller Balance Queries ========== */

  function balanceWrapped() public view virtual override returns (uint256) {
    address module = userModules[msg.sender];
    return IERC20(token).balanceOf(module == address(0) ? msg.sender : module);
  }

  function balanceUnderlying() external view virtual override returns (uint256) {
    address module = userModules[msg.sender];
    return IERC20(token).balanceOf(module == address(0) ? msg.sender : module);
  }

/* ========== Token Actions ========== */

  function deposit(uint256 amountUnderlying) external virtual override returns (uint256 amountMinted) {
    require(amountUnderlying > 0, "deposit 0");
    AaveV2UserModule module = getOrCreateUserModule();
    underlying.safeTransferFrom(msg.sender, address(module), amountUnderlying);
    module.deposit(amountUnderlying);
    return amountUnderlying;
  }

  function depositETH() external payable virtual override returns (uint256 amountMinted) {
    require(msg.value > 0, "deposit 0");
    AaveV2UserModule module = getOrCreateUserModule();
    IWETH(underlying).deposit{value: msg.value}();
    underlying.safeTransfer(address(module), msg.value);
    module.deposit(msg.value);
    return msg.value;
  }

  function withdraw(uint256 amountToken) public virtual override returns (uint256 amountReceived) {
    require(amountToken > 0, "withdraw 0");
    address module = userModules[msg.sender];
    if (module == address(0)) {
      token.safeTransferFrom(msg.sender, address(this), amountToken);
      pool.withdraw(underlying, amountToken, msg.sender);
      return amountToken;
    }
    AaveV2UserModule(payable(module)).withdraw(amountToken, true);
    return amountToken;
  }

  function withdrawAsETH(uint256 amountToken) public virtual override returns (uint256 amountReceived) {
    require(amountToken > 0, "withdraw 0");
    address module = userModules[msg.sender];
    if (module == address(0)) {
      token.safeTransferFrom(msg.sender, address(this), amountToken);
      pool.withdraw(underlying, amountToken, address(this));
    } else {
      AaveV2UserModule(payable(module)).withdraw(amountToken, false);
    }
    IWETH(underlying).withdraw(amountToken);
    msg.sender.safeTransferETH(amountToken);
    return amountToken;
  }

  function withdrawAll() public virtual override returns (uint256 amountReceived) {
    return withdraw(balanceWrapped());
  }

  function withdrawAllAsETH() public virtual override returns (uint256 amountReceived) {
    return withdrawAsETH(balanceWrapped());
  }

  function withdrawUnderlying(uint256 amountUnderlying) external virtual override returns (uint256 amountBurned) {
    return withdraw(amountUnderlying);
  }

  function withdrawUnderlyingAsETH(uint256 amountUnderlying) external virtual override returns (uint256 amountBurned) {
    return withdrawAsETH(amountUnderlying);
  }

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external virtual override returns (uint256 amountReceived) {
    require(amountUnderlying > 0, "withdraw 0");
    uint256 amountAvailable = availableLiquidity();
    amountReceived = amountAvailable < amountUnderlying ? amountAvailable : amountUnderlying;
    withdraw(amountReceived);
  }
}