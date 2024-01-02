// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV3FlashCallback.sol";
import "./FixedPoint96.sol";
import "./LowGasSafeMath.sol";
import "./PeripheryPayments.sol";
import "./PeripheryImmutableState.sol";
import "./ISwapRouter.sol";
import "./PoolAddress.sol";
import "./CallbackValidation.sol";
import "./TransferHelper.sol";
import "./IDecentralizedIndex.sol";
import "./IUniswapV2Pair.sol";
import "./IV3TwapUtilities.sol";
import "./IERC20Metadata.sol";
import "./IWETH.sol";

contract ArbitragePP is
  IUniswapV3FlashCallback,
  Ownable,
  PeripheryImmutableState,
  PeripheryPayments
{
  using LowGasSafeMath for uint256;
  using LowGasSafeMath for int256;
  using SafeERC20 for IERC20;

  address constant V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address constant V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address constant V3_DAI_WETH = 0x60594a405d53811d3BC4766596EFD80fd545A270;
  address constant PP = 0x515e7fd1C29263DFF8d987f15FA00c12cd10A49b;
  address constant PEAS = 0x02f92800F57BCD74066F5709F1Daa1A4302Df875;

  IV3TwapUtilities immutable V3_UTILS;

  struct FlashCallbackData {
    address caller;
    address borrowPool;
    PoolAddress.PoolKey borrowPoolKey;
    uint256 borrowAmount0;
    uint256 borrowAmount1;
  }

  constructor(
    IV3TwapUtilities _v3TwapUtilities,
    address _factory,
    address _WETH9
  ) PeripheryImmutableState(_factory, _WETH9) {
    V3_UTILS = _v3TwapUtilities;
  }

  function arbAllThePeas(uint256 _amountDAI) external {
    IUniswapV3Pool _borrowPool = IUniswapV3Pool(V3_DAI_WETH);
    address _t0 = _borrowPool.token0();
    (uint256 _borrowAmount0, uint256 _borrowAmount1) = DAI == _t0
      ? (_amountDAI, uint256(0))
      : (uint256(0), _amountDAI);

    PoolAddress.PoolKey memory _borrowPoolKey = PoolAddress.PoolKey({
      token0: _borrowPool.token0(),
      token1: _borrowPool.token1(),
      fee: _borrowPool.fee()
    });

    _borrowPool.flash(
      address(this),
      _borrowAmount0,
      _borrowAmount1,
      abi.encode(
        FlashCallbackData({
          caller: msg.sender,
          borrowPool: address(_borrowPool),
          borrowPoolKey: _borrowPoolKey,
          borrowAmount0: _borrowAmount0,
          borrowAmount1: _borrowAmount1
        })
      )
    );
  }

  function uniswapV3FlashCallback(
    uint256 fee0,
    uint256 fee1,
    bytes calldata data
  ) external override {
    FlashCallbackData memory decoded = abi.decode(data, (FlashCallbackData));
    CallbackValidation.verifyCallback(factory, decoded.borrowPoolKey);

    uint256 _daiBal = IERC20(DAI).balanceOf(address(this));

    // get PEAS and PP current prices
    address _v2Factory = IUniswapV2Router02(V2_ROUTER).factory();
    address _ppPair = IUniswapV2Factory(_v2Factory).getPair(DAI, PP);
    (uint112 _r0, uint112 _r1, ) = IUniswapV2Pair(_ppPair).getReserves();
    uint256 _ppPriceUSDX96 = (DAI < PP)
      ? (_r0 * FixedPoint96.Q96) / _r1
      : (_r1 * FixedPoint96.Q96) / _r0;

    PoolAddress.PoolKey memory _peasV3PoolKey = PoolAddress.PoolKey({
      token0: DAI < PEAS ? DAI : PEAS,
      token1: DAI < PEAS ? PEAS : DAI,
      fee: 10000
    });
    address _peasV3Pool = PoolAddress.computeAddress(factory, _peasV3PoolKey);
    uint256 _peasPriceUSDX96 = V3_UTILS.getPoolPriceUSDX96(
      _peasV3Pool,
      V3_DAI_WETH,
      WETH9
    );

    if (_peasPriceUSDX96 < _ppPriceUSDX96) {
      // market buy PEAS, wrap, then dump on PP chart
      IERC20(DAI).safeIncreaseAllowance(V3_ROUTER, _daiBal);
      ISwapRouter(V3_ROUTER).exactInputSingle(
        ISwapRouter.ExactInputSingleParams({
          tokenIn: DAI,
          tokenOut: PEAS,
          fee: 10000,
          recipient: address(this),
          deadline: block.timestamp,
          amountIn: _daiBal,
          amountOutMinimum: 0, // use mevblocker
          sqrtPriceLimitX96: 0
        })
      );

      uint256 _peasBal = IERC20(PEAS).balanceOf(address(this));
      IERC20(PEAS).safeIncreaseAllowance(PP, _peasBal);
      IDecentralizedIndex(PP).bond(PEAS, _peasBal);

      uint256 _ppBal = IERC20(PP).balanceOf(address(this));
      IERC20(PP).safeIncreaseAllowance(V2_ROUTER, _ppBal);
      address[] memory _path = new address[](2);
      _path[0] = PP;
      _path[1] = DAI;
      IUniswapV2Router02(V2_ROUTER).swapExactTokensForTokens(
        _ppBal,
        0, // use mevblocker
        _path,
        address(this),
        block.timestamp
      );
    } else {
      // market buy PP, unwrap to PEAS, dump on PEAS chart
      IERC20(DAI).safeIncreaseAllowance(V2_ROUTER, _daiBal);
      address[] memory _path = new address[](2);
      _path[0] = DAI;
      _path[1] = PP;
      IUniswapV2Router02(V2_ROUTER).swapExactTokensForTokens(
        _daiBal,
        0, // use mevblocker
        _path,
        address(this),
        block.timestamp
      );

      address[] memory _token = new address[](0);
      uint8[] memory _am = new uint8[](0);
      IDecentralizedIndex(PP).debond(
        IERC20(PP).balanceOf(address(this)),
        _token,
        _am
      );

      uint256 _peasBal = IERC20(PEAS).balanceOf(address(this));
      IERC20(PEAS).safeIncreaseAllowance(V3_ROUTER, _peasBal);
      ISwapRouter(V3_ROUTER).exactInputSingle(
        ISwapRouter.ExactInputSingleParams({
          tokenIn: PEAS,
          tokenOut: DAI,
          fee: 10000,
          recipient: address(this),
          deadline: block.timestamp,
          amountIn: _peasBal,
          amountOutMinimum: 0, // use mevblocker
          sqrtPriceLimitX96: 0
        })
      );
    }

    // pay back borrowed funds to borrowPool
    _payBackBorrowedFunds(fee0, fee1, decoded);

    // pay back profit to owner
    _sendProfit(decoded);
  }

  function _payBackBorrowedFunds(
    uint256 _fee0,
    uint256 _fee1,
    FlashCallbackData memory decoded
  ) internal {
    address _borrowToken0 = decoded.borrowPoolKey.token0;
    address _borrowToken1 = decoded.borrowPoolKey.token1;

    uint256 _borrowAmount0Owed = LowGasSafeMath.add(
      decoded.borrowAmount0,
      _fee0
    );
    uint256 _borrowAmount1Owed = LowGasSafeMath.add(
      decoded.borrowAmount1,
      _fee1
    );

    if (_borrowAmount0Owed > 0) {
      require(
        ERC20(_borrowToken0).balanceOf(address(this)) > _borrowAmount0Owed,
        'PAYBACK0'
      );
      TransferHelper.safeApprove(
        _borrowToken0,
        address(this),
        _borrowAmount0Owed
      );
      pay(_borrowToken0, address(this), msg.sender, _borrowAmount0Owed);
    }

    if (_borrowAmount1Owed > 0) {
      require(
        ERC20(_borrowToken1).balanceOf(address(this)) > _borrowAmount1Owed,
        'PAYBACK1'
      );
      TransferHelper.safeApprove(
        _borrowToken1,
        address(this),
        _borrowAmount1Owed
      );
      pay(_borrowToken1, address(this), msg.sender, _borrowAmount1Owed);
    }
  }

  function _sendProfit(FlashCallbackData memory decoded) internal {
    uint256 _daiBal = IERC20(DAI).balanceOf(address(this));
    IERC20(DAI).safeIncreaseAllowance(V2_ROUTER, _daiBal);
    address[] memory _path = new address[](2);
    _path[0] = DAI;
    _path[1] = WETH9;
    IUniswapV2Router02(V2_ROUTER).swapExactTokensForETH(
      _daiBal,
      0, // use mevblocker
      _path,
      decoded.caller,
      block.timestamp
    );
  }
}
