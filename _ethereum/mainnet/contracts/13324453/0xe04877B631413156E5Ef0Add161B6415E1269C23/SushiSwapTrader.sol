// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";
import "./ISushiSwapTrader.sol";
import "./ISushiSwapFactory.sol";
import "./ISushiSwapRouter.sol";
import "./ISushiSwapPair.sol";
import "./IIntegrationMap.sol";

/// @notice Integrates 0x Nodes to SushiSwap
contract SushiSwapTrader is
  Initializable,
  ModuleMapConsumer,
  Controlled,
  ISushiSwapTrader
{
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  uint24 private constant SLIPPAGE_DENOMINATOR = 1_000_000;
  uint24 private slippageNumerator;
  address private factoryAddress;
  address private swapRouterAddress;

  event ExecutedSwapExactInput(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    uint256 amountOut
  );

  event FailedSwapExactInput(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin
  );

  event SushiSwapSlippageNumeratorUpdated(uint24 slippageNumerator);

  /// @param controllers_ The addresses of the controlling contracts
  /// @param moduleMap_ The address of the module map contract
  /// @param factoryAddress_ The address of the SushiSwap factory contract
  /// @param swapRouterAddress_ The address of the SushiSwap swap router contract
  /// @param slippageNumerator_ The number divided by the slippage denominator to get the slippage percentage
  function initialize(
    address[] memory controllers_,
    address moduleMap_,
    address factoryAddress_,
    address swapRouterAddress_,
    uint24 slippageNumerator_
  ) public initializer {
    require(
      slippageNumerator <= SLIPPAGE_DENOMINATOR,
      "SushiSwapTrader::initialize: Slippage Numerator must be less than or equal to slippage denominator"
    );
    __Controlled_init(controllers_, moduleMap_);
    __ModuleMapConsumer_init(moduleMap_);
    factoryAddress = factoryAddress_;
    swapRouterAddress = swapRouterAddress_;
    slippageNumerator = slippageNumerator_;
  }

  /// @param slippageNumerator_ The number divided by the slippage denominator to get the slippage percentage
  function updateSlippageNumerator(uint24 slippageNumerator_)
    external
    override
    onlyManager
  {
    require(
      slippageNumerator_ != slippageNumerator,
      "SushiSwapTrader::setSlippageNumerator: Slippage numerator must be set to a new value"
    );
    require(
      slippageNumerator <= SLIPPAGE_DENOMINATOR,
      "SushiSwapTrader::setSlippageNumerator: Slippage Numerator must be less than or equal to slippage denominator"
    );

    slippageNumerator = slippageNumerator_;

    emit SushiSwapSlippageNumeratorUpdated(slippageNumerator_);
  }

  /// @notice Swaps all WETH held in this contract for BIOS and sends to the kernel
  /// @return Bool indicating whether the trade succeeded
  function biosBuyBack() external override onlyController returns (bool) {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    address wethAddress = integrationMap.getWethTokenAddress();
    address biosAddress = integrationMap.getBiosTokenAddress();
    uint256 wethAmountIn = IERC20MetadataUpgradeable(wethAddress).balanceOf(
      address(this)
    );

    uint256 biosAmountOutMin = getAmountOutMinimum(
      wethAddress,
      biosAddress,
      wethAmountIn
    );

    return
      swapExactInput(
        wethAddress,
        integrationMap.getBiosTokenAddress(),
        moduleMap.getModuleAddress(Modules.Kernel),
        wethAmountIn,
        biosAmountOutMin
      );
  }

  /// @param tokenIn The address of the input token
  /// @param tokenOut The address of the output token
  /// @param recipient The address of the token out recipient
  /// @param amountIn The exact amount of the input to swap
  /// @param amountOutMin The minimum amount of tokenOut to receive from the swap
  /// @return bool Indicates whether the swap succeeded
  function swapExactInput(
    address tokenIn,
    address tokenOut,
    address recipient,
    uint256 amountIn,
    uint256 amountOutMin
  ) public override onlyController returns (bool) {
    require(
      IERC20MetadataUpgradeable(tokenIn).balanceOf(address(this)) >= amountIn,
      "SushiSwapTrader::swapExactInput: Balance is less than trade amount"
    );

    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = tokenOut;
    uint256 deadline = block.timestamp;

    if (
      IERC20MetadataUpgradeable(tokenIn).allowance(
        address(this),
        swapRouterAddress
      ) == 0
    ) {
      IERC20MetadataUpgradeable(tokenIn).safeApprove(
        swapRouterAddress,
        type(uint256).max
      );
    }

    uint256 tokenOutBalanceBefore = IERC20MetadataUpgradeable(tokenOut)
      .balanceOf(recipient);

    try
      ISushiSwapRouter(swapRouterAddress).swapExactTokensForTokens(
        amountIn,
        amountOutMin,
        path,
        recipient,
        deadline
      )
    {
      emit ExecutedSwapExactInput(
        tokenIn,
        tokenOut,
        amountIn,
        amountOutMin,
        IERC20MetadataUpgradeable(tokenOut).balanceOf(recipient) -
          tokenOutBalanceBefore
      );
      return true;
    } catch {
      emit FailedSwapExactInput(tokenIn, tokenOut, amountIn, amountOutMin);
      return false;
    }
  }

  /// @param tokenIn The address of the input token
  /// @param tokenOut The address of the output token
  /// @param amountIn The exact amount of the input to swap
  /// @return amountOutMinimum The minimum amount of tokenOut to receive, factoring in allowable slippage
  function getAmountOutMinimum(
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) public view returns (uint256 amountOutMinimum) {
    amountOutMinimum =
      (getAmountOut(tokenIn, tokenOut, amountIn) *
        (SLIPPAGE_DENOMINATOR - slippageNumerator)) /
      SLIPPAGE_DENOMINATOR;
  }

  /// @param tokenIn The address of the input token
  /// @param tokenOut The address of the output token
  /// @param amountIn The exact amount of the input to swap
  /// @return amountOut The estimated amount of tokenOut to receive
  function getAmountOut(
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) public view returns (uint256 amountOut) {
    require(
      amountIn > 0,
      "SushiSwapTrader::getAmountOut: amountIn must be greater than zero"
    );
    (uint256 reserveIn, uint256 reserveOut) = getReserves(tokenIn, tokenOut);
    require(
      reserveIn > 0 && reserveOut > 0,
      "SushiSwapTrader::getAmountOut: No liquidity in pool reserves"
    );
    uint256 amountInWithFee = amountIn * 997;
    uint256 numerator = amountInWithFee * (reserveOut);
    uint256 denominator = reserveIn * 1000 + amountInWithFee;
    amountOut = numerator / denominator;
  }

  /// @param tokenA The address of tokenA
  /// @param tokenB The address of tokenB
  /// @return reserveA The reserve balance of tokenA in the pool
  /// @return reserveB The reserve balance of tokenB in the pool
  function getReserves(address tokenA, address tokenB)
    internal
    view
    returns (uint256 reserveA, uint256 reserveB)
  {
    (address token0, ) = getTokensSorted(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = ISushiSwapPair(
      getPairFor(tokenA, tokenB)
    ).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  /// @param tokenA The address of tokenA
  /// @param tokenB The address of tokenB
  /// @return token0 The address of sorted token0
  /// @return token1 The address of sorted token1
  function getTokensSorted(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(
      tokenA != tokenB,
      "SushiSwapTrader::sortToken: Identical token addresses"
    );
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "SushiSwapTrader::sortToken: Zero address");
  }

  /// @param tokenA The address of tokenA
  /// @param tokenB The address of tokenB
  /// @return pair The address of the SushiSwap pool contract
  function getPairFor(address tokenA, address tokenB)
    internal
    view
    returns (address pair)
  {
    pair = ISushiSwapFactory(factoryAddress).getPair(tokenA, tokenB);
  }

  /// @return SushiSwap Factory address
  function getFactoryAddress() public view returns (address) {
    return factoryAddress;
  }

  /// @return The slippage numerator
  function getSlippageNumerator() public view returns (uint24) {
    return slippageNumerator;
  }

  /// @return The slippage denominator
  function getSlippageDenominator() public pure returns (uint24) {
    return SLIPPAGE_DENOMINATOR;
  }
}
