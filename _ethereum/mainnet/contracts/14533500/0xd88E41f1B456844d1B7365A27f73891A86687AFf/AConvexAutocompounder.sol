// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Router02.sol";

import "./ICurve_2.sol";
import "./ICurve_3.sol";
import "./IConvexBooster.sol";
import "./IBaseRewardPool.sol";
import "./IPairVault.sol";
import "./OndoRegistryClient.sol";
import "./Multiex.sol";
import "./OndoLibrary.sol";

abstract contract AConvexAutocompounder is Multiex {
  using OndoSaferERC20 for IERC20;

  struct SwapPath {
    address router;
    address[] path;
  }
  struct LPSetting {
    IERC20 lpAddress;
    address lpMinterAddress;
    IBaseRewardPool cvxReward;
    uint256 cvxPID;
    uint256 allocPoints;
  }

  // constants
  // Curve settings
  IERC20 public constant THREE_CRV_LP =
    IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
  ICurve_3 public constant THREE_CRV_MINTER =
    ICurve_3(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
  // Convex Settings
  IConvexBooster public constant CONVEX_BOOSTER =
    IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
  address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  IERC20 public immutable stableAsset; // DAI/USDC/USDT
  int128 public immutable stableAssetCurveIndex; // asset index of 3Crv pool

  mapping(uint256 => uint256) public balanceOf; // Shares of each vaultId
  uint256 public totalSupply;

  LPSetting[] public lpSettings;
  uint256 public totalAllocPoints;
  address[] public rewardTokens;
  mapping(address => SwapPath) public swapPaths;
  mapping(address => int128) public stableToIndex;

  /**
   * @dev Setup contract dependencies here
   * @param _stableAsset single asset
   * @param _lpSettings The array of lp Setting structs for the tokens which we
   * Wish to farm on CVX
   * @param _rewardTokens An array of tokens that we will reveive as rewards for providing
   * the LP tokens to CVX
   */
  constructor(
    address _stableAsset,
    LPSetting[] memory _lpSettings,
    address[] memory _rewardTokens
  ) {
    require(
      _stableAsset == DAI || _stableAsset == USDT || _stableAsset == USDC,
      "Invalid Stable Asset"
    );
    stableAsset = IERC20(_stableAsset);
    stableToIndex[DAI] = int128(0);
    stableToIndex[USDC] = int128(1);
    stableToIndex[USDT] = int128(2);

    stableAssetCurveIndex = stableToIndex[_stableAsset];
    // calc stable asset index of 3pool
    uint256 _totalAllocPoints;
    uint256 __length = _lpSettings.length;
    for (uint256 i = 0; i < __length; ++i) {
      lpSettings.push(_lpSettings[i]);
      _totalAllocPoints += _lpSettings[i].allocPoints;
    }
    totalAllocPoints = _totalAllocPoints;
    rewardTokens = _rewardTokens;
  }

  /**
   * @dev Set swap path of assets
   * @param _assets asset array
   * @param _paths path array
   */
  function setSwapPaths(address[] calldata _assets, SwapPath[] calldata _paths)
    external
    isAuthorized(OLib.STRATEGIST_ROLE)
  {
    require(_assets.length == _paths.length, "Invalid Inputs");
    for (uint256 i = 0; i < _assets.length; i++) {
      swapPaths[_assets[i]] = _paths[i];
    }
  }

  /**
   * @dev Set reward tokens
   * @param _rewardTokens reward tokens array
   */
  function setRewardTokens(address[] calldata _rewardTokens)
    external
    isAuthorized(OLib.STRATEGIST_ROLE)
  {
    rewardTokens = _rewardTokens;
  }

  /**
   * @dev Get all lp amounts in array format
   */
  function getLPAmounts() public view returns (uint256[] memory lpAmounts) {
    uint256 __length = lpSettings.length;
    lpAmounts = new uint256[](__length);
    for (uint256 i = 0; i < __length; ++i) {
      lpAmounts[i] = lpSettings[i].cvxReward.balanceOf(address(this));
    }
  }

  /**
   * @dev Get total 3CRV lp amounts
   */
  function get3CRVAmount() public view returns (uint256 total3CRVAmount) {
    uint256 __length = lpSettings.length;
    for (uint256 i = 0; i < __length; ++i) {
      uint256 lpAmount = lpSettings[i].cvxReward.balanceOf(address(this));
      ICurve_2 minter = ICurve_2(lpSettings[i].lpMinterAddress);
      if (lpAmount > 0 && address(minter) != address(THREE_CRV_LP)) {
        if (minter.coins(0) == address(THREE_CRV_LP)) {
          lpAmount = minter.calc_withdraw_one_coin(lpAmount, 0);
        } else if (minter.coins(1) == address(THREE_CRV_LP)) {
          lpAmount = minter.calc_withdraw_one_coin(lpAmount, 1);
        } else {
          revert();
        }
      }

      total3CRVAmount += lpAmount;
    }
  }

  /**
   * @dev compound: claim -> swap -> invest
   */
  function compound() external isAuthorized(OLib.STRATEGIST_ROLE) {
    _claim();

    _swapRewardTokensToStableAsset();

    _splitAndDepositConvex();
  }

  // compound can use much gas - suggest to have separate functions for compound as well

  /**
   * @dev claim rewards from convex
   */
  function _claim() internal {
    // claim rewards
    uint256 __length = lpSettings.length;
    for (uint256 i = 0; i < __length; ++i) {
      lpSettings[i].cvxReward.getReward();
    }
  }

  /**
   * @dev swap reward tokens to stable asset
   */
  function _swapRewardTokensToStableAsset() internal {
    // swap rewards tokens to DAI/USDC/USDT
    uint256 __length = rewardTokens.length;
    for (uint256 i = 0; i < rewardTokens.length; ++i) {
      _swap(rewardTokens[i]);
    }
  }

  /**
   * @dev split stable asset based on alloc points and deposit into convex
   */

  function _splitAndDepositConvex() internal {
    uint256 total3CRVAmount = _mint3CRV();
    uint256 __length = lpSettings.length;

    if (total3CRVAmount > 10000) {
      for (uint256 i = 0; i < __length; ++i) {
        LPSetting memory setting = lpSettings[i];

        // mint curve lp based on alloc points
        uint256 newLpAmount =
          _mintLPFrom3CRV(
            setting.lpAddress,
            setting.lpMinterAddress,
            OLib.safeMulDiv(
              total3CRVAmount,
              setting.allocPoints,
              totalAllocPoints
            )
          );

        IERC20(setting.lpAddress).ondoSafeIncreaseAllowance(
          address(CONVEX_BOOSTER),
          newLpAmount
        );
        // deposit into convex
        CONVEX_BOOSTER.deposit(setting.cvxPID, newLpAmount, true); //_stake=true: stake LP into convex rewards contract
      }
    }
  }

  // Internal Functions

  function _swap(address rewardAsset) internal {
    uint256 amount = IERC20(rewardAsset).balanceOf(address(this));
    if (amount > 10000) {
      SwapPath memory data = swapPaths[rewardAsset];

      IERC20(rewardAsset).ondoSafeIncreaseAllowance(data.router, amount);
      IUniswapV2Router02(data.router).swapExactTokensForTokens(
        amount,
        0, // minimum output amount
        data.path,
        address(this),
        block.timestamp
      );
    }
  }

  function _mint3CRV() internal returns (uint256 lpAmount) {
    uint256[3] memory amounts;
    amounts[0] = IERC20(DAI).balanceOf(address(this));
    amounts[1] = IERC20(USDC).balanceOf(address(this));
    amounts[2] = IERC20(USDT).balanceOf(address(this));

    if (amounts[0] + amounts[1] + amounts[2] > 10000) {
      IERC20(DAI).ondoSafeIncreaseAllowance(
        address(THREE_CRV_MINTER),
        amounts[0]
      );
      IERC20(USDC).ondoSafeIncreaseAllowance(
        address(THREE_CRV_MINTER),
        amounts[1]
      );
      IERC20(USDT).ondoSafeIncreaseAllowance(
        address(THREE_CRV_MINTER),
        amounts[2]
      );

      uint256 balanceBefore = THREE_CRV_LP.balanceOf(address(this));
      THREE_CRV_MINTER.add_liquidity(
        amounts,
        0 // minimum mint amount
      );
      lpAmount = THREE_CRV_LP.balanceOf(address(this)) - balanceBefore;
    }
  }

  function _mintLPFrom3CRV(
    IERC20 lp,
    address minter,
    uint256 threeCRVAmount
  ) internal returns (uint256 lpAmount) {
    if (lp == THREE_CRV_LP) {
      return threeCRVAmount;
    }

    uint256[2] memory amounts;
    if (ICurve_2(minter).coins(0) == address(THREE_CRV_LP)) {
      amounts[0] = threeCRVAmount;
    } else if (ICurve_2(minter).coins(1) == address(THREE_CRV_LP)) {
      amounts[1] = threeCRVAmount;
    } else {
      revert();
    }

    THREE_CRV_LP.ondoSafeIncreaseAllowance(minter, threeCRVAmount);

    uint256 balanceBefore = lp.balanceOf(address(this));
    ICurve_2(minter).add_liquidity(
      amounts,
      0 // minimum mint amount
    );
    return lp.balanceOf(address(this)) - balanceBefore;
  }

  function getLpLength() public view returns (uint256) {
    return lpSettings.length;
  }

  function _mint(uint256 poolId, uint256 amount) internal {
    balanceOf[poolId] += amount;
    totalSupply += amount;
  }

  function _burn(uint256 poolId, uint256 amount) internal {
    require(balanceOf[poolId] >= amount, "Insufficient Balance");
    balanceOf[poolId] -= amount;
    totalSupply -= amount;
  }
}
