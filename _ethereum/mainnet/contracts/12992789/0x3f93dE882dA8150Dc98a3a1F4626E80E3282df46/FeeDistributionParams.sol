// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";
import "./ICurvePool.sol";
import "./IQDUCK.sol";

contract FeeDistributionParams {
  using SafeERC20 for IERC20;

  IQDUCK public constant qDuck = IQDUCK(0xE85d5FE256F5f5c9E446502aE994fDA12fd6700a);

  IERC20 public constant usdp = IERC20(0x1456688345527bE1f37E9e627DA0837D6f08C925);
  IERC20 public constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  IERC20 public constant duck = IERC20(0x92E187a03B6CD19CB6AF293ba17F2745Fd2357D5);

  ICurvePool public constant crvUsdpPool = ICurvePool(0x42d7025938bEc20B69cBae5A77421082407f053A);

  // SushiSwap initially
  IUniswapV2Router02 public stableToWethRouter = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

  // ShibaSwap initially
  IUniswapV2Router02 public wethToDuckRouter = IUniswapV2Router02(0x03f7724180AA6b939894B5Ca4314783B0b36b329);

  // Unit multisig initially
  address public gov = 0xae37E8f9a3f960eE090706Fa4db41Ca2f2C56Cb8;

  // USDC initially
  int128 public stableIndex = 2;

  mapping (address => bool) public canSwap;

  modifier g() {
    require(msg.sender == gov, "FeeDistribution: !gov");
    _;
  }

  modifier s() {
    require(canSwap[msg.sender], "FeeDistribution: can't swap");
    _;
  }

  constructor () {
    canSwap[msg.sender] = true;
    approveTokens();
  }

  function setGov(address _gov) external g {
    gov = _gov;
  }

  function setSwapper(address _swapper, bool _permit) external g {
    canSwap[_swapper] = _permit;
  }

  function setParams(int128 _stableIndex, address _stableToWethRouter, address _wethDuckRouter) external g {
    stableIndex = _stableIndex;
    stableToWethRouter = IUniswapV2Router02(_stableToWethRouter);
    wethToDuckRouter = IUniswapV2Router02(_wethDuckRouter);
  }

  function stableToken() public view returns(IERC20) {
    return IERC20(crvUsdpPool.base_coins(uint(int(stableIndex)) - 1));
  }

  function approveTokens() public {
    stableToken().safeApprove(address(stableToWethRouter), type(uint).max);
    weth.approve(address(wethToDuckRouter), type(uint).max);
  }

  function stableToWethPath() public view returns(address[] memory path) {
    path = new address[](2);
    path[0] = address(stableToken());
    path[1] = address(weth);
  }

  function wethToDuckPath() public pure returns(address[] memory path) {
    path = new address[](2);
    path[0] = address(weth);
    path[1] = address(duck);
  }
}
