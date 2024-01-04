pragma solidity 0.5.16;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";

import "./Governable.sol";
import "./IRewardPool.sol";
import "./IUniswapV2Router02.sol";

import "./IFeeRewardForwarderV4.sol";
import "./IUniversalLiquidator.sol";
import "./IUniversalLiquidatorRegistry.sol";
import "./IRewardDistributionSwitcher.sol";

contract FeeRewardForwarder is IFeeRewardForwarderV4, Governable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public farm;

  // grain
  // grain is a burnable ERC20 token that is deployed by Harvest
  // we sell crops to buy back grain and burn it
  address public grain;
  uint256 public grainShareNumerator = 0;
  uint256 public grainShareDenominator = 100;

  // In case we're not buying back grain immediately,
  // we liquidate the crops into the grainBackerToken
  // and send it to an EOA `grainBuybackReserve`
  bool public grainImmediateBuyback = true;
  address public grainBackerToken = address(0);
  address public grainBuybackReserve = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);

  // the targeted reward token to convert everything to
  // initializing so that we do not need to call setTokenPool(...)
  address public targetToken;
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
    address _grain,
    address _universalLiquidatorRegistry
  ) public Governable(_storage) {
    require(_grain != address(0), "_grain not defined");
    require(_farm != address(0), "_farm not defined");
    require(_universalLiquidatorRegistry != address(0), "_universalLiquidatorRegistry not defined");
    grain = _grain;
    farm = _farm;
    targetToken = farm;
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
    // To buy back grain, our `targetToken` needs to be FARM
    require(farm == IRewardPool(_pool).rewardToken(), "Rewardpool's token is not FARM");
    profitSharingPool = _pool;
    targetToken = farm;
    emit TokenPoolSet(targetToken, _pool);
  }

  // Transfers the funds from the msg.sender to the pool
  // under normal circumstances, msg.sender is the strategy
  function poolNotifyFixedTarget(address _token, uint256 _amount) external {
    uint256 remainingAmount = _amount;
    // Note: targetToken could only be FARM or NULL.
    // it is only used to check that the rewardPool is set.
    if (targetToken == address(0)) {
      return; // a No-op if target pool is not set yet
    }
    if (_token == farm) {
      // this is already the right token
      // Note: Under current structure, this would be FARM.
      // This would pass on the grain buy back as it would be the special case
      // designed for NotifyHelper calls
      // This is assuming that NO strategy would notify profits in FARM
      IERC20(_token).safeTransferFrom(msg.sender, profitSharingPool, _amount);
      IRewardPool(profitSharingPool).notifyRewardAmount(_amount);
    } else {
      // If grainImmediateBuyback is set to false, then funds to buy back grain needs to be sent to an address

      if (grainShareNumerator != 0 && !grainImmediateBuyback) {
        require(grainBuybackReserve != address(0), "grainBuybackReserve should not be empty");
        uint256 balanceToSend = _amount.mul(grainShareNumerator).div(grainShareDenominator);
        remainingAmount = _amount.sub(balanceToSend);

        // If the liquidation path is set, liquidate to grainBackerToken and send it over
        // if not, send the crops immediately
        // this also covers the case when the _token is the grainBackerToken

        if (storedLiquidationPaths[_token][grainBackerToken].length > 0
          || IUniversalLiquidatorRegistry(universalLiquidatorRegistry).getPath(uniDex, _token, grainBackerToken).length > 1
        ) {
          IERC20(_token).safeTransferFrom(msg.sender, address(this), balanceToSend);
          liquidate(_token, grainBackerToken, balanceToSend);
          // send the grainBackerToken to the reserve
          IERC20(grainBackerToken).safeTransfer(grainBuybackReserve, IERC20(grainBackerToken).balanceOf(address(this)));
        } else {
          IERC20(_token).safeTransferFrom(msg.sender, grainBuybackReserve, balanceToSend);
        }
      }

      // we need to convert _token to FARM
      // note that we removed the check "if liquidation path exists".
      // it is already enforced later down the road
      IERC20(_token).safeTransferFrom(msg.sender, address(this), remainingAmount);
      uint256 balanceToSwap = IERC20(_token).balanceOf(address(this));
      liquidate(_token, farm, balanceToSwap);

      // if grain buyback is activated, then sell some FARM to buy and burn grain
      if(grainShareNumerator != 0 && grainImmediateBuyback) {
        uint256 balanceToBuyback = (IERC20(farm).balanceOf(address(this))).mul(grainShareNumerator).div(grainShareDenominator);
        liquidate(farm, grain, balanceToBuyback);

        // burn all the grains in this contract
        ERC20Burnable(grain).burn(IERC20(grain).balanceOf(address(this)));
      }

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

    address uliquidator = IUniversalLiquidatorRegistry(universalLiquidatorRegistry).universalLiquidator();
    IERC20(_from).safeApprove(uliquidator, 0);
    IERC20(_from).safeApprove(uliquidator, balanceToSwap);

    if (storedLiquidationDexes[_from][_to].length > 0) {
      // if custom liquidation is specified
      IUniversalLiquidator(uliquidator).swapTokenOnMultipleDEXes(
        balanceToSwap,
        1,
        address(this), // target
        storedLiquidationDexes[_from][_to],
        storedLiquidationPaths[_from][_to]
      );
    } else {
      // otherwise, liquidating on Uniswap
      IUniversalLiquidator(uliquidator).swapTokenOnDEX(
        balanceToSwap,
        1,
        address(this), // target
        uniDex,
        IUniversalLiquidatorRegistry(universalLiquidatorRegistry).getPath(uniDex, _from, _to)
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

  function setGrainBuybackRatio(uint256 _grainShareNumerator, uint256 _grainShareDenominator) public onlyGovernance {
    require(_grainShareDenominator >= _grainShareNumerator, "numerator cannot be greater than denominator");
    require(_grainShareDenominator != 0, "_grainShareDenominator cannot be 0");

    grainShareNumerator = _grainShareNumerator;
    grainShareDenominator = _grainShareDenominator;
  }

  function setGrainConfig(
    uint256 _grainShareNumerator,
    uint256 _grainShareDenominator,
    bool _grainImmediateBuyback,
    address _grainBackerToken,
    address _grainBuybackReserve
  ) external onlyGovernance {
    require(_grainBuybackReserve != address(0), "_grainBuybackReserve is empty");
    // grainBackerToken can be address(0), this way the forwarder will send the crops directly
    // since it cannot find a path.
    // grainShareNumerator can be 0, this means that no grain is being bought back
    setGrainBuybackRatio(_grainShareNumerator, _grainShareDenominator);

    grainImmediateBuyback = _grainImmediateBuyback;
    grainBackerToken = _grainBackerToken;
    grainBuybackReserve = _grainBuybackReserve;
  }
}
