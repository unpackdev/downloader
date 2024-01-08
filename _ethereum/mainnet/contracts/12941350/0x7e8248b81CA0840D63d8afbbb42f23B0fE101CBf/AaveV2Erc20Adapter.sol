// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./AaveV2Interfaces.sol";
import "./ITokenAdapter.sol";
import "./IERC20.sol";
import "./LowGasSafeMath.sol";
import "./TransferHelper.sol";
import "./SymbolHelper.sol";
import "./RayMul.sol";
import "./ReserveConfigurationLib.sol";
import "./MinimalSignedMath.sol";
import "./CloneLibrary.sol";


contract AaveV2Erc20Adapter is IErc20Adapter {
  using MinimalSignedMath for uint256;
  using LowGasSafeMath for uint256;
  using RayMul for uint256;
  using SymbolHelper for address;
  using TransferHelper for address;

/* ========== Constants ========== */

  ILendingPoolAddressesProvider public immutable addressesProvider;
  address public constant aave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  IAaveDistributionManager internal constant distributor = IAaveDistributionManager(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);
  ILendingPool public immutable pool;

/* ========== Storage ========== */

  address public userModuleImplementation;
  address public override underlying;
  address public override token;
  mapping(address => address) public userModules;
  // Pre-calculated and stored in the initializer to reduce gas costs in `getRewardsAPR`.
  uint256 internal _oneUnderlyingToken;

/* ========== Constructor & Initializer ========== */

  constructor(ILendingPoolAddressesProvider _addressesProvider) {
    addressesProvider = _addressesProvider;
    pool = _addressesProvider.getLendingPool();
  }

  function initialize(address _underlying, address _token) public virtual {
    require(underlying == address(0) && token == address(0), "initialized");
    require(_underlying != address(0) && _token != address(0), "bad address");
    underlying = _underlying;
    token = _token;
    userModuleImplementation = address(new AaveV2UserModule(
      addressesProvider,
      _underlying,
      _token
    ));
    _oneUnderlyingToken = 10 ** IERC20Metadata(_underlying).decimals();
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
    uint256 underlyingValue = underlyingPrice.mul(_totalLiquidity) / _oneUnderlyingToken;
    uint256 rewardsValue = aavePrice.mul(emissionsPerSecond.mul(365 days));
    return rewardsValue / underlyingValue;
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

  function withdraw(uint256 amountToken) public virtual override returns (uint256 amountReceived) {
    require(amountToken > 0, "withdraw 0");
    address module = userModules[msg.sender];
    if (module == address(0)) {
      token.safeTransferFrom(msg.sender, address(this), amountToken);
      pool.withdraw(underlying, amountToken, msg.sender);
      return amountToken;
    }
    AaveV2UserModule(payable(module)).withdraw(amountToken, true);
    amountReceived = amountToken;
  }

  function withdrawAll() external virtual override returns (uint256 amountReceived) {
    return withdraw(balanceWrapped());
  }

  function withdrawUnderlying(uint256 amountUnderlying) external virtual override returns (uint256 amountBurned) {
    amountBurned = withdraw(amountUnderlying);
  }

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external virtual override returns (uint256 amountReceived) {
    require(amountUnderlying > 0, "withdraw 0");
    uint256 amountAvailable = availableLiquidity();
    amountReceived = amountAvailable < amountUnderlying ? amountAvailable : amountUnderlying;
    withdraw(amountReceived);
  }
}


contract AaveV2UserModule {
  using TransferHelper for address;

  IStakedAave internal constant stkAave = IStakedAave(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
  IAaveDistributionManager internal constant incentives = IAaveDistributionManager(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);
  ILendingPool internal immutable pool;
  address internal immutable underlying;
  address internal immutable aToken;
  address internal immutable adapter;

  address internal user;
  bool public assetHasRewards;
  uint32 public cooldownUnlockAt;

  constructor(
    ILendingPoolAddressesProvider addressesProvider,
    address _underlying,
    address _aToken
  ) {
    adapter = msg.sender;
    underlying = _underlying;
    aToken = _aToken;
    ILendingPool _pool = addressesProvider.getLendingPool();
    pool = _pool;
  }

  function initialize(address _user) external {
    require(msg.sender == adapter && user == address(0));
    user = _user;
    underlying.safeApproveMax(address(pool));
    (, uint256 emissionPerSecond,) = incentives.getAssetData(aToken);
    assetHasRewards = emissionPerSecond > 0;
  }

  function setHasRewards() external {
    (, uint256 emissionPerSecond,) = incentives.getAssetData(aToken);
    assetHasRewards = emissionPerSecond > 0;
  }

  function _claimAndTriggerCooldown() internal {
    address[] memory assets = new address[](1);
    assets[0] = aToken;
    uint256 r = incentives.getUserUnclaimedRewards(address(this));
    if (r > 0) {
      incentives.claimRewards(assets, r, address(this));
      stkAave.cooldown();
      uint256 cooldownDuration = stkAave.COOLDOWN_SECONDS();
      cooldownUnlockAt = uint32(block.timestamp + cooldownDuration);
    }
  }

  function poke() public {
    // We do not check if the asset has rewards inside of poke so that if
    // rewards are accrued and then the asset's incentives are set to zero,
    // the existing rewards can still be manually claimed.
    // If there's not a pending cooldown, claim any rewards and begin the cooldown
    // If there is a pending cooldown:
    // - If it is over, redeem stkAave, reset the timer, claim stkAave and begin new cooldown
    // - If it is not over, do nothing
    if (cooldownUnlockAt > 0) {
      if (cooldownUnlockAt < block.timestamp) {
        stkAave.redeem(user, type(uint256).max);
        cooldownUnlockAt = 0;
      } else {
        return;
      }
    }
    _claimAndTriggerCooldown();
  }

  function deposit(uint256 amount) external {
    require(msg.sender == adapter, "!adapter");
    pool.deposit(underlying, amount, address(this), 0);
    if (assetHasRewards) poke();
  }

  function withdraw(uint256 amount, bool toUser) external {
    require(msg.sender == adapter, "!adapter");
    pool.withdraw(underlying, amount, toUser ? user : adapter);
    if (assetHasRewards) poke();
  }
}