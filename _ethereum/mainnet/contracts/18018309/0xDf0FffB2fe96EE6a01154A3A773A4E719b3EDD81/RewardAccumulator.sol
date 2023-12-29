// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./SafeERC20.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeCast.sol";
import "./Initializable.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./OracleLibrary.sol";

import "./IRewardAccumulator.sol";
import "./IRarityPool.sol";
import "./IRareStakingRegistry.sol";

/// @author charlescrain
/// @title RewardAccumulator
/// @notice The reward accumulator accumulates rewards and allows for swapping of ETH or ERC20 tokens in exchange for RARE.
/// @dev It is one base user per contract. This is the implementation contract for a beacon proxy.
contract RewardAccumulator is IRewardAccumulator, ReentrancyGuardUpgradeable {
  using SafeCast for uint256;
  using SafeCast for uint128;

  /*//////////////////////////////////////////////////////////////////////////
                          Private Contract Storage
  //////////////////////////////////////////////////////////////////////////*/
  // Address of the staking pool
  IRarityPool private stakingPool;

  /*//////////////////////////////////////////////////////////////////////////
                              Constructor
  //////////////////////////////////////////////////////////////////////////*/
  constructor() {
    _disableInitializers();
  }

  /*//////////////////////////////////////////////////////////////////////////
                              Initializer
  //////////////////////////////////////////////////////////////////////////*/
  function initialize(address _stakingPool) external initializer {
    stakingPool = IRarityPool(_stakingPool);
  }

  /*//////////////////////////////////////////////////////////////////////////
                          Public Write Functions
  //////////////////////////////////////////////////////////////////////////*/
  /// @inheritdoc IRewardAccumulator
  function rewardSwap(
    address _tokenOut,
    uint256 _minAmountOut,
    uint128 _rareIn
  ) external nonReentrant {
    if (_minAmountOut == 0) revert ParameterValueTooLow( );
    if (_rareIn == 0) revert ParameterValueTooLow( );

    IERC20 rare = IERC20(IRareStakingRegistry(stakingPool.getStakingRegistry()).getRareAddress());

    // Empty any excess $RARE to the staking pool
    if (rare.balanceOf(address(this)) > 0) {
      SafeERC20.safeTransfer(IERC20(rare),address(stakingPool), rare.balanceOf(address(this)));
    }
    // If ETH, check balance
    if (_tokenOut == address(0) && address(this).balance < _minAmountOut) {
      revert InsufficientFunds();
    }

    // If ERC20, check balance
    if (_tokenOut != address(0) && IERC20(_tokenOut).balanceOf(address(this)) < _minAmountOut) {
      revert InsufficientFunds();
    }

    // Check if is $RARE address
    if (_tokenOut == address(rare)) {
      revert CannotSwapRareForRare();
    }

    // Estimate the price
    uint256 amountOut = estimateRarePrice(_tokenOut, _rareIn);

    // Ensure that amount to return meets _minAmoutOut requirements
    if (amountOut < _minAmountOut) {
      revert RarePriceTooLow();
    }

    // Add the $RARE to the staking pool as rewards
    stakingPool.addRewards(msg.sender, _rareIn);

    // If ETH, send the swap amount
    if (_tokenOut == address(0)) {
      Address.sendValue(payable(msg.sender), amountOut);
    } else {
      // Send the swap amount as ERC20
      SafeERC20.safeTransfer(IERC20(_tokenOut), msg.sender, amountOut);
    }

    emit RewardAccumulator(msg.sender, _tokenOut, amountOut, _rareIn);
  }

  /*//////////////////////////////////////////////////////////////////////////
                          External/Public Read Functions
  //////////////////////////////////////////////////////////////////////////*/
  /// @inheritdoc IRewardAccumulator
  function estimateRarePrice(address _tokenOut, uint128 _rareAmountIn) public view returns (uint256) {
    IRareStakingRegistry stakingRegistry = IRareStakingRegistry(stakingPool.getStakingRegistry());
    address weth = stakingRegistry.getWethAddress();
    // Null address implies ETH
    address tokenOut = _tokenOut == address(0) ? weth : _tokenOut;

    // If poolOut is the null address and the token out isn't the WETH addres, it's unsupported
    if (stakingRegistry.getSwapPool(tokenOut) == address(0) && tokenOut != weth) {
      revert UnsupportedERC20Token();
    }

    uint32 secondsAgo = 30 minutes;
    uint32[] memory secondsAgos = new uint32[](2);
    secondsAgos[0] = secondsAgo;
    secondsAgos[1] = 0;

    // Look up cumulative ticks for 30 minutes
    (int56[] memory tickCumulatives, ) = IUniswapV3Pool(stakingRegistry.getSwapPool(stakingRegistry.getRareAddress()))
      .observe(secondsAgos);

    // Calculate the the tick to obtain a quote
    int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
    int24 tick = int24(tickCumulativesDelta / int32(secondsAgo));
    // Always round to negative infinity
    if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int32(secondsAgo) != 0)) {
      tick--;
    }

    // Get ETH/WETH amount for the $RARE in
    uint256 ethAmount = ((
      OracleLibrary.getQuoteAtTick(tick, _rareAmountIn.toUint128(), stakingRegistry.getRareAddress(), weth)
    ) * (100_00 + stakingRegistry.getDiscountPercentage())) / 100_00;

    // If tokenOut is WETH we can simply return this amount for the price
    if (tokenOut == weth) {
      return ethAmount;
    }

    // If checking for Other_Token/RARE price, look up pool pair for Other_token/WETH
    (int56[] memory otherTickCumulatives, ) = IUniswapV3Pool(stakingRegistry.getSwapPool(tokenOut)).observe(secondsAgos);
    int56 otherTickCumulativesDelta = otherTickCumulatives[1] - otherTickCumulatives[0];
    int24 otherTick = int24(otherTickCumulativesDelta / int32(secondsAgo));

    return OracleLibrary.getQuoteAtTick(otherTick, ethAmount.toUint128(), weth, tokenOut);
  }

  /*//////////////////////////////////////////////////////////////////////////
                          Receive
  //////////////////////////////////////////////////////////////////////////*/

  receive() external payable {}
}
