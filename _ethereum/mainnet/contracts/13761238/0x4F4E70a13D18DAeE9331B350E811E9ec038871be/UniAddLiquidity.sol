// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "./IERC20.sol";

interface UniswapV2Router02 {
  function addLiquidity(
    address,
    address,
    uint256,
    uint256,
    uint256,
    uint256,
    address,
    uint256
  ) external;
}

contract UniAddLiquidity {
  address public constant UNI_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public constant POP = 0xD0Cd466b34A24fcB2f87676278AF2005Ca8A78c4;
  address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  uint256 public popLiquidity = 0;
  uint256 public usdcLiquidity = 0;
  uint256 public minPopLiquidity = 0;
  uint256 public minUsdcLiquidity = 0;

  address public immutable admin;
  address public immutable dao;

  constructor(address _admin, address _dao) {
    admin = _admin;
    dao = _dao;
  }

  function setLiquidity(
    uint256 _popLiquidity,
    uint256 _usdcLiquidity,
    uint256 _minPopLiquidity,
    uint256 _minUsdcLiquidity
  ) public {
    require(msg.sender == admin, "Sender must be admin");
    require(_popLiquidity <= 500_000e18, "POP liquidity must not exceed maximum");
    require(_usdcLiquidity <= 1_000_000e6, "USDC liquidity must not exceed maximum");
    require(_minPopLiquidity <= _popLiquidity);
    require(_minUsdcLiquidity <= _usdcLiquidity);

    popLiquidity = _popLiquidity;
    usdcLiquidity = _usdcLiquidity;
    minPopLiquidity = _minPopLiquidity;
    minUsdcLiquidity = _minUsdcLiquidity;
  }

  function addLiquidity() public {
    require(IERC20(POP).transferFrom(msg.sender, address(this), popLiquidity), "Transfer of POP must succeed");
    require(IERC20(USDC).transferFrom(msg.sender, address(this), usdcLiquidity), "Transfer of USDC must succeed");
    IERC20(POP).approve(UNI_ROUTER, popLiquidity);
    IERC20(USDC).approve(UNI_ROUTER, usdcLiquidity);
    UniswapV2Router02(UNI_ROUTER).addLiquidity(
      POP,
      USDC,
      popLiquidity,
      usdcLiquidity,
      minPopLiquidity,
      minUsdcLiquidity,
      dao,
      block.timestamp + 1 days
    );
  }
}
