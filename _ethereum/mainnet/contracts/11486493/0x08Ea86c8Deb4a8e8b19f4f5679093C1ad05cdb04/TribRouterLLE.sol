// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.7.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ILockedLiquidityEvent.sol";
import "./ITDAO.sol";
import "./IWETH.sol";
import "./IBalancer.sol";
import "./IContribute.sol";
import "./IDetailERC20.sol";

contract TribRouterLLE {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public pair;
  address public weth;
  address public mUSD;
  address public trib;
  address public tribMinter;
  address public tDao;
  address public lockedLiquidityEvent;

  event TribPurchased(
    address indexed from,
    uint256 amountIn,
    uint256 amountOut
  );
  event EthToMUSDConversion(
    uint256 amountIn,
    uint256 amountOut,
    uint256 spotPrice
  );
  event AddedLiquidity(
    address indexed from,
    uint256 amountIn,
    uint256 amountOut
  );

  constructor(
    address _pair,
    address _tribMinter,
    address _tDao
  ) public {
    pair = _pair;
    tribMinter = _tribMinter;
    tDao = _tDao;

    trib = IContribute(tribMinter).token();
    address[] memory tokens;
    address tokenA;
    address tokenB;
    tokens = IBalancer(pair).getCurrentTokens();
    tokenA = tokens[0];
    tokenB = tokens[1];
    weth = keccak256(bytes(IDetailERC20(tokenA).symbol())) ==
      keccak256(bytes('WETH'))
      ? tokenA
      : tokenB;
    mUSD = weth == tokenA ? tokenB : tokenA;
    lockedLiquidityEvent = ITDAO(tDao).lockedLiquidityEvent();

    _approveMax(weth, pair);
    _approveMax(mUSD, tribMinter);
    _approveMax(trib, lockedLiquidityEvent);
  }

  receive() external payable {
    _addLiquidityWithEth();
  }

  // @notice Calculates the amount of TRIB given Eth amount.
  function calcTribOut(uint256 amount) external view returns (uint256 tribOut) {
    uint256 amountMUSD = _calcMUSDOut(amount);
    tribOut = IContribute(tribMinter).getReserveToTokensTaxed(amountMUSD);
  }

  // @notice Purchases Trib using Weth.
  // @TODO - Call external function that adds liquidity to LLE.
  function addLiquidity(uint256 amount) external {
    require(amount != 0, 'TribRouterLLE: Must deposit Weth.');
    IERC20(weth).safeTransferFrom(msg.sender, address(this), amount);
    _addLiquidity(msg.sender, amount);
  }

  function _addLiquidityWithEth() internal {
    uint256 amountIn = msg.value;
    IWETH(weth).deposit{value: amountIn}();
    require(
      IERC20(weth).balanceOf(address(this)) != 0,
      'TribRouterLLE: Weth deposit failed.'
    );
    _addLiquidity(msg.sender, amountIn);
  }

  function _addLiquidity(address _account, uint256 _amount) internal {
    uint256 amountMUSD = _convertWethToMUSD(_amount);
    uint256 amountTrib = _buyTrib(_account, amountMUSD);

    if (
      IERC20(trib).allowance(address(this), lockedLiquidityEvent) < amountTrib
    ) {
      _approveMax(trib, lockedLiquidityEvent);
    }

    ILockedLiquidityEvent(lockedLiquidityEvent).addLiquidityFor(
      _account,
      amountTrib
    );

    emit AddedLiquidity(_account, _amount, amountTrib);
  }

  // @notice Estimates amount of mUSD to be purchased given Eth amount.
  function _calcMUSDOut(uint256 _amount)
    internal
    view
    returns (uint256 _amountMUSD)
  {
    uint256 amountIn = _amount;
    uint256 weightMUSD = IBalancer(pair).getNormalizedWeight(mUSD);
    uint256 weightWeth = IBalancer(pair).getNormalizedWeight(weth);
    uint256 balanceMUSD = IERC20(mUSD).balanceOf(pair);
    uint256 balanceWeth = IERC20(weth).balanceOf(pair);
    uint256 swapFee = IBalancer(pair).getSwapFee();

    _amountMUSD = IBalancer(pair).calcOutGivenIn(
      balanceWeth,
      weightWeth,
      balanceMUSD,
      weightMUSD,
      amountIn,
      swapFee
    );
  }

  // @notice Converts Weth to mUSD.
  function _convertWethToMUSD(uint256 _amount)
    internal
    returns (uint256 _amountMUSD)
  {
    uint256 amountIn = _amount;

    uint256 price = IBalancer(pair).getSpotPrice(mUSD, weth);
    uint256 minAmount = price.mul(amountIn).div(1e18);
    uint256 range = 10;
    uint256 min = minAmount.sub(minAmount.div(range));
    uint256 max = price.add(price.div(range));

    if (IERC20(weth).allowance(address(this), pair) < amountIn) {
      _approveMax(weth, pair);
    }

    uint256 spotPriceAfter;

    (_amountMUSD, spotPriceAfter) = IBalancer(pair).swapExactAmountIn(
      weth,
      amountIn,
      mUSD,
      min,
      max
    );

    emit EthToMUSDConversion(amountIn, _amountMUSD, spotPriceAfter);
  }

  // @notice Sends mUSD to minter in order to buy Trib.
  function _buyTrib(address _account, uint256 _amount)
    internal
    returns (uint256 _totalTrib)
  {
    uint256 amount = _amount;

    if (IERC20(mUSD).allowance(address(this), tribMinter) < amount) {
      _approveMax(mUSD, tribMinter);
    }

    _totalTrib = IContribute(tribMinter).getReserveToTokensTaxed(amount);
    IContribute(tribMinter).invest(amount);

    emit TribPurchased(_account, _amount, _totalTrib);
  }

  // @notice Approves max. uint value for gas savings.
  function _approveMax(address _token, address _spender) internal {
    IERC20(_token).safeApprove(_spender, uint256(-1));
  }
}
