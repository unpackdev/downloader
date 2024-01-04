pragma solidity 0.5.16;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";

import "./Governable.sol";
import "./IRewardPool.sol";
import "./IVault.sol";
import "./IUniswapV2Router02.sol";

import "./IFeeRewardForwarderV6.sol";
import "./ILiquidator.sol";
import "./ILiquidatorRegistry.sol";
import "./IRewardDistributionSwitcher.sol";

contract FeeRewardForwarder is IFeeRewardForwarderV6, Governable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public farm;
  address public iFarm;

  address public profitSharingPool = address(0x8f5adC58b32D4e5Ca02EAC0E293D35855999436C);

  bytes32 public uniDex = bytes32(uint256(keccak256("uni")));
  bytes32 public sushiDex = bytes32(uint256(keccak256("sushi")));

  // by default, all tokens are liquidated on Uniswap,
  // and the liquidation path is taken directly from the universal liquidator registry
  // to override this, can set a custom liquidation path and dexes
  mapping(address => mapping(address => address[])) public storedLiquidationPaths;
  mapping(address => mapping(address => bytes32[])) public storedLiquidationDexes;

  address public universalLiquidatorRegistry;

  address constant public sushi = address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
  address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address constant public mis = address(0x4b4D2e899658FB59b1D518b68fe836B100ee8958);
  address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

  event TokenPoolSet(address token, address pool);

  constructor(address _storage,
    address _farm,
    address _iFarm,
    address _universalLiquidatorRegistry
  ) public Governable(_storage) {
    require(_farm != address(0), "_farm not defined");
    require(_universalLiquidatorRegistry != address(0), "_universalLiquidatorRegistry not defined");
    farm = _farm;
    iFarm = _iFarm;
    universalLiquidatorRegistry = _universalLiquidatorRegistry;

    // pre-existing settings
    storedLiquidationPaths[sushi][farm] = [sushi, weth, farm];
    storedLiquidationDexes[sushi][farm] = [sushiDex, uniDex];

    storedLiquidationPaths[mis][farm] = [mis, usdt, farm];
    storedLiquidationDexes[mis][farm] = [sushiDex, uniDex];
  }

  /*
  *   Set the pool that will receive the reward token
  *   based on the address of the reward Token
  */
  function setTokenPool(address _pool) public onlyGovernance {
    require(farm == IRewardPool(_pool).rewardToken(), "Rewardpool's token is not FARM");
    profitSharingPool = _pool;
    emit TokenPoolSet(farm, _pool);
  }

  // Transfers the funds from the msg.sender to the pool
  // under normal circumstances, msg.sender is the strategy
  function poolNotifyFixedTarget(address _token, uint256 _amount) public {
    uint256 remainingAmount = _amount;
    if (_token == farm) {
      // this is already the right token
      // Note: Under current structure, this would be FARM.
      IERC20(_token).safeTransferFrom(msg.sender, profitSharingPool, _amount);
      IRewardPool(profitSharingPool).notifyRewardAmount(_amount);
    } else {
      // we need to convert _token to FARM
      // note that we removed the check "if liquidation path exists".
      // it is already enforced later down the road
      IERC20(_token).safeTransferFrom(msg.sender, address(this), remainingAmount);
      uint256 balanceToSwap = IERC20(_token).balanceOf(address(this));
      liquidate(_token, farm, balanceToSwap);

      // now we can send this token forward
      uint256 convertedRewardAmount = IERC20(farm).balanceOf(address(this));
      IERC20(farm).safeTransfer(profitSharingPool, convertedRewardAmount);
      IRewardPool(profitSharingPool).notifyRewardAmount(convertedRewardAmount);
    }
  }

  function liquidate(address _from, address _to, uint256 balanceToSwap) internal {
    if (balanceToSwap == 0) {
      return;
    }

    address uliquidator = ILiquidatorRegistry(universalLiquidatorRegistry).universalLiquidator();
    IERC20(_from).safeApprove(uliquidator, 0);
    IERC20(_from).safeApprove(uliquidator, balanceToSwap);

    if (storedLiquidationDexes[_from][_to].length > 0) {
      // if custom liquidation is specified
      ILiquidator(uliquidator).swapTokenOnMultipleDEXes(
        balanceToSwap,
        1,
        address(this), // target
        storedLiquidationDexes[_from][_to],
        storedLiquidationPaths[_from][_to]
      );
    } else {
      // otherwise, liquidating on Uniswap
      ILiquidator(uliquidator).swapTokenOnDEX(
        balanceToSwap,
        1,
        address(this), // target
        uniDex,
        ILiquidatorRegistry(universalLiquidatorRegistry).getPath(uniDex, _from, _to)
      );
    }
  }

  /**
  * Sets whether liquidation happens through Uniswap, Sushiswap, or others
  * as well as the path across the exchanges
  */
  function configureLiquidation(address[] memory path, bytes32[] memory dexes) public onlyGovernance {
    address fromToken = path[0];
    address toToken = path[path.length - 1];

    require(dexes.length == path.length - 1, "lengths do not match");

    storedLiquidationPaths[fromToken][toToken] = path;
    storedLiquidationDexes[fromToken][toToken] = dexes;
  }

  /**
  * Notifies a given _rewardPool with _maxBuyback by converting it into iFARM
  */
  function notifyIFarmBuybackAmount(address _token, address _rewardPool, uint256 _maxBuyback) public {
    require(IRewardPool(_rewardPool).rewardToken() == iFarm, "The target pool's reward must be iFARM");

    if (_token == farm) {
      // this is already the right token
      // Note: Under current structure, this would be FARM.

      // need to wrap into iFARM first
      IERC20(farm).safeTransferFrom(msg.sender, address(this), _maxBuyback);
      IERC20(farm).safeApprove(iFarm, 0);
      IERC20(farm).safeApprove(iFarm, _maxBuyback);
      IVault(iFarm).deposit(_maxBuyback);

      uint256 iFarmBalance = IERC20(iFarm).balanceOf(address(this));
      if (iFarmBalance > 0) {
        IERC20(iFarm).safeTransfer(_rewardPool, iFarmBalance);
        IRewardPool(_rewardPool).notifyRewardAmount(iFarmBalance);
      }
    } else {
      // we need to convert _token to FARM
      // note that we removed the check "if liquidation path exists".
      // it is already enforced later down the road
      IERC20(_token).safeTransferFrom(msg.sender, address(this), _maxBuyback);
      uint256 balanceToSwap = IERC20(_token).balanceOf(address(this));
      liquidate(_token, farm, balanceToSwap);

      // now we can send this token forward
      uint256 convertedRewardAmount = IERC20(farm).balanceOf(address(this));

      IERC20(farm).safeApprove(iFarm, 0);
      IERC20(farm).safeApprove(iFarm, convertedRewardAmount);
      IVault(iFarm).deposit(convertedRewardAmount);

      uint256 iFarmBalance = IERC20(iFarm).balanceOf(address(this));
      if (iFarmBalance > 0) {
        IERC20(iFarm).safeTransfer(_rewardPool, iFarmBalance);
        IRewardPool(_rewardPool).notifyRewardAmount(iFarmBalance);
      }
    }
  }

  /**
  * Notifies PS with _feeAmount and the _rewardPool with _maxBuyback
  */
  function notifyFeeAndBuybackAmounts(uint256 _feeAmount, address _rewardPool, uint256 _maxBuyback) external {
    if (_feeAmount > 0) {
      // notifying fee
      poolNotifyFixedTarget(farm, _feeAmount);
    }

    if (_maxBuyback > 0) {
      notifyIFarmBuybackAmount(farm, _rewardPool, _maxBuyback);
    }
  }

  /**
  * Notifies PS with _feeAmount and the _rewardPool with _maxBuyback, in token
  */
  function notifyFeeAndBuybackAmounts(address _token, uint256 _feeAmount, address _rewardPool, uint256 _maxBuyback) external {
    if (_feeAmount > 0) {
      // notifying fee
      poolNotifyFixedTarget(_token, _feeAmount);
    }

    if (_maxBuyback > 0) {
      notifyIFarmBuybackAmount(_token, _rewardPool, _maxBuyback);
    }
  }
}
