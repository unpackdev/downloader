// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.7.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IWETH.sol";
import "./IBalancer.sol";
import "./IContribute.sol";
import "./IDetailERC20.sol";

contract TribRouter {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public pair;
  address public weth;
  address public mUSD;
  address public trib;
  address public tribMinter;

  event TribPurchased(address indexed from, uint256 amountIn, uint256 amountOut);
  event EthToMUSDConversion(uint256 amountIn, uint256 amountOut, uint256 spotPrice);

  constructor(address _pair, address _tribMinter) public {
    pair = _pair;
    tribMinter = _tribMinter;

    trib = IContribute(tribMinter).token();
    address[] memory tokens;
    address tokenA;
    address tokenB;
    tokens = IBalancer(pair).getCurrentTokens();
    tokenA = tokens[0];
    tokenB = tokens[1];
    weth = keccak256(bytes(IDetailERC20(tokenA).symbol())) == keccak256(bytes("WETH")) ? tokenA : tokenB;
    mUSD = weth == tokenA ? tokenB : tokenA;

    _approveMax(weth, pair);
    _approveMax(mUSD, tribMinter);
  }

  receive() external payable {
    _purchaseTrib();
  }

  // @notice Calculates the amount of TRIB given Eth amount.
  function calcTribOut(uint256 amount) external view returns (uint256 tribOut) {
    uint256 amountMUSD = _calcMUSDOut(amount);
    tribOut = IContribute(tribMinter).getReserveToTokensTaxed(amountMUSD);
  }

  // @notice Purchases Trib using Weth.
  function purchaseTrib(uint256 amount) external {
    require(amount != 0, "TribRouter: Must deposit Weth.");
    IERC20(weth).safeTransferFrom(msg.sender, address(this), amount);
    require(_purchase(msg.sender, amount), "TribRouter: Trib purchase failed.");
  }

  // @notice Purchases Trib using Eth.
  function _purchaseTrib() internal {
    uint256 amountIn = msg.value;
    IWETH(weth).deposit{value : amountIn}();
    require(IERC20(weth).balanceOf(address(this)) != 0 , "TribRouter: Weth deposit failed.");
    require(_purchase(msg.sender, amountIn), "TribRouter: Trib purchase failed.");
  }

  // @notice Converts Weth to mUSD, purchases Trib from minter and sends to user.
  function _purchase(address _account, uint256 _amount) internal returns (bool) {
    uint256 amountMUSD = _convertWethToMUSD(_amount);
    uint256 amountTrib = _buyTrib(_account, amountMUSD);
    IERC20(trib).safeTransfer(_account, amountTrib);

    return true;
  }

  // @notice Estimates amount of mUSD to be purchased given Eth amount.
  function _calcMUSDOut(uint256 _amount) internal view returns (uint256 _amountMUSD){
    uint amountIn = _amount;
    uint weightMUSD = IBalancer(pair).getNormalizedWeight(mUSD);
    uint weightWeth = IBalancer(pair).getNormalizedWeight(weth);
    uint balanceMUSD = IERC20(mUSD).balanceOf(pair);
    uint balanceWeth = IERC20(weth).balanceOf(pair);
    uint swapFee = IBalancer(pair).getSwapFee();

    _amountMUSD = IBalancer(pair).calcOutGivenIn(balanceWeth, weightWeth, balanceMUSD, weightMUSD, amountIn, swapFee);
  }

  // @notice Converts Weth to mUSD.
  function _convertWethToMUSD(uint256 _amount) internal returns (uint256 _amountMUSD) {
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

    (_amountMUSD, spotPriceAfter) = IBalancer(pair).swapExactAmountIn(weth, amountIn, mUSD, min, max);

    emit EthToMUSDConversion(amountIn, _amountMUSD, spotPriceAfter);
  }

  // @notice Sends mUSD to minter in order to buy Trib.
  function _buyTrib(address _account, uint256 _amount) internal returns (uint256 _totalTrib) {
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
