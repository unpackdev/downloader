// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;
pragma abicoder v2;

import "TickMath.sol";
import "FixedPoint128.sol";
import "FullMath.sol";
import "SqrtPriceMath.sol";

import "PositionKey.sol";
import "PoolAddress.sol";
import "SafeERC20.sol";
import "LiquidityAmounts.sol";

import "IUniswapV3Pool.sol";

import "IERC20.sol";
import "IUniswapV3Helper.sol";
import "INonfungiblePositionManager.sol";

import "ERC721Receivable.sol";

contract UniswapV3Helper is IUniswapV3Helper, ERC721Receivable {

  using SafeERC20 for IERC20;

  INonfungiblePositionManager internal constant positionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

  function removeLiquidity(
    uint _tokenId,
    uint _minOutput0,
    uint _minOutput1
  ) external override returns(uint, uint) {

    uint128 liquidity = uint128(positionLiquidity(_tokenId));

    // NonfungiblePositionManager.decreaseLiquidity fails in case of 0 liquidity
    // https://github.com/Uniswap/v3-periphery/blob/main/contracts/NonfungiblePositionManager.sol#L265
    if (liquidity > 0) {

      positionManager.safeTransferFrom(msg.sender, address(this), _tokenId);

      INonfungiblePositionManager.DecreaseLiquidityParams memory params =
        INonfungiblePositionManager.DecreaseLiquidityParams({
          tokenId:    _tokenId,
          liquidity:  liquidity,
          amount0Min: _minOutput0,
          amount1Min: _minOutput1,
          deadline:   block.timestamp
        });

      positionManager.decreaseLiquidity(params);
    }

    (uint amount0, uint amount1) = _collectFees(_tokenId);
    _safeTransferAmounts(_tokenId, amount0, amount1);
    positionManager.burn(_tokenId);

    return (amount0, amount1);
  }

  function collectFees(uint _tokenId) external override returns(uint, uint) {

    positionManager.safeTransferFrom(msg.sender, address(this), _tokenId);

    (uint amount0, uint amount1) = _collectFees(_tokenId);

    _safeTransferAmounts(_tokenId, amount0, amount1);
    positionManager.safeTransferFrom(address(this), msg.sender, _tokenId);

    return (amount0, amount1);
  }

  function getPoolAddress(
    address _factory,
    address _token0,
    address _token1,
    uint24  _fee
  ) external pure returns(address) {
    PoolAddress.PoolKey memory poolKey =
      PoolAddress.PoolKey({ token0: _token0, token1: _token1, fee: _fee });
    address pairAddress = PoolAddress.computeAddress(_factory, poolKey);
    return pairAddress;
  }

  // This function answer the question:
  // If the current token prices were as follows (_price0, _price1),
  // what would be token amounts of this position look like?
  // This function is used to determine USD value of the position inside of the lending pair
  // Price inputs are in token prices related to each other
  function positionAmounts(
    uint _tokenId,
    uint _price0,
    uint _price1
  ) external view override returns(uint, uint) {
    uint160 sqrtPriceX96 = uint160(getSqrtPriceX96(_price0, _price1));
    int24 tick = getTickAtSqrtRatio(sqrtPriceX96);
    return getUserTokenAmount(_tokenId, tick);
  }

  function getPrice(uint _sqrtPriceX96) external view returns(uint256 price) {
    return (_sqrtPriceX96 * _sqrtPriceX96 * 1e18) >> (96 * 2);
  }

  function getUserInterest(uint _tokenId) external view returns(uint, uint) {
    (
      ,
      ,
      ,
      ,
      ,
      ,
      ,
      uint128 liquidity,
      uint positionFeeGrowthInside0LastX128,
      uint positionFeeGrowthInside1LastX128,
      ,

    ) = positionManager.positions(_tokenId);

    (uint feeGrowthInside0LastX128, uint feeGrowthInside1LastX128) =
      getPositionGrowthInside(_tokenId);
    return (
      uint128(
        FullMath.mulDiv(
          feeGrowthInside0LastX128 - positionFeeGrowthInside0LastX128,
          liquidity,
          FixedPoint128.Q128
        )
      ),
      uint128(
        FullMath.mulDiv(
          feeGrowthInside1LastX128 - positionFeeGrowthInside1LastX128,
          liquidity,
          FixedPoint128.Q128
        )
      )
    );
  }

  // 1 / ((5 / 1000 + 5 / 1000 + 5 / 1000) / 15) = 1000

  function getSqrtRatioAtTick(int24 _tick) public pure returns(uint160) {
    return TickMath.getSqrtRatioAtTick(_tick);
  }

  function getTickAtSqrtRatio(uint160 _sqrtPriceX96) public pure returns(int24) {
    return TickMath.getTickAtSqrtRatio(_sqrtPriceX96);
  }

  function positionTokens(uint _tokenId) public view override returns(address, address) {
    (, , address tokenA, address tokenB, , , , , , , ,) = positionManager.positions(_tokenId);
    return (tokenA, tokenB);
  }

  function positionLiquidity(uint _tokenId) public view returns(uint) {
    (, , , , , , , uint liquidity, , , ,) = positionManager.positions(_tokenId);
    return liquidity;
  }

  function getUserTokenAmount(
    uint  _tokenId,
    int24 _tick
  ) public view returns (uint, uint) {
    (
      ,
      ,
      ,
      ,
      ,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      ,
      ,
      ,

    ) = positionManager.positions(_tokenId);

    return liquidityToAmounts(_tick, tickLower, tickUpper, liquidity);
  }

  function liquidityToAmounts(
    int24 _tickCurrent,
    int24 _tickLower,
    int24 _tickUpper,
    uint128 _liquidity
  ) public view returns(uint amount0, uint amount1) {

    return LiquidityAmounts.getAmountsForLiquidity(
      TickMath.getSqrtRatioAtTick(_tickCurrent),
      TickMath.getSqrtRatioAtTick(_tickLower),
      TickMath.getSqrtRatioAtTick(_tickUpper),
      _liquidity
    );
  }

  function getSqrtPriceX96(uint _amount0, uint _amount1) public pure returns(uint) {
    uint ratioX192 = (_amount0 << 192) / _amount1;
    return _sqrt(ratioX192);
  }

  function getPositionGrowthInside(uint _tokenId) public view returns(uint, uint) {
    (
      ,
      ,
      address token0,
      address token1,
      uint24 fee,
      int24 tickLower,
      int24 tickUpper,
      ,
      ,
      ,
      ,

    ) = positionManager.positions(_tokenId);

    IUniswapV3Pool pool =
      IUniswapV3Pool(
        PoolAddress.computeAddress(
          positionManager.factory(),
          PoolAddress.PoolKey({
            token0: token0,
            token1: token1,
            fee: fee
          })
        )
      );

    (
      ,
      uint feeGrowthInside0LastX128,
      uint feeGrowthInside1LastX128,
      ,

    ) =
      pool.positions(
        PositionKey.compute(address(positionManager), tickLower, tickUpper)
      );

    return (feeGrowthInside0LastX128, feeGrowthInside1LastX128);
  }

  function _collectFees(uint _tokenId) internal returns(uint, uint) {

    INonfungiblePositionManager.CollectParams memory params =
      INonfungiblePositionManager.CollectParams({
      tokenId: _tokenId,
      recipient: address(this),
      amount0Max: type(uint128).max,
      amount1Max: type(uint128).max
      });

    return positionManager.collect(params);
  }

  function _safeTransferAmounts(uint _tokenId, uint _amount0, uint _amount1) internal {
    (address token0, address token1) = positionTokens(_tokenId);
    _safeTransfer(token0, msg.sender, _amount0);
    _safeTransfer(token1, msg.sender, _amount1);
  }

  // Can't use TransferHelper due since it's on another version fo Solidity
  function _safeTransfer(address _token, address _recipient, uint _amount) internal {
    require(_amount > 0, "UniswapV3Helper: amount must be > 0");
    IERC20(_token).safeTransfer(_recipient, _amount);
  }

  function _sqrt(uint _x) internal pure returns(uint y) {
    uint z = (_x + 1) / 2;
    y = _x;
    while (z < y) {
      y = z;
      z = (_x / z + z) / 2;
    }
  }
}
