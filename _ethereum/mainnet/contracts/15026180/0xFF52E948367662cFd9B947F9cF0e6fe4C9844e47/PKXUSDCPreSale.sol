// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

import "./IUniswapV2Router02.sol";

contract PokerXSale is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  IERC20 public pkxToken = IERC20(0xEdff951a6Be79Ef4F00a034bB9FcD19b57bacBBF);

  uint256 public softcap = 50000 * 10 ** 6;
  uint256 public tokenLiquidityAmount = 600000000000 * 10 ** 18;
  uint256 public tokenSaleAmount = 200000000000 * 10 ** 18;
  uint256 public totalRaised = 0;
  mapping(address => uint256) public balances;

  bool public ended = false;

  constructor() { }

  function setPKX(address _token) external onlyOwner {
    pkxToken = IERC20(_token);
  }

  function setSoftCap(uint256 amount) external onlyOwner {
    softcap = amount;
  }

  function setTokenLiquidityAmount(uint256 amount) external onlyOwner {
    tokenLiquidityAmount = amount;
  }

  function setTokenSaleAmount(uint256 amount) external onlyOwner {
    tokenSaleAmount = amount;
  }

  function endPresale() external onlyOwner {
    ended = true;
  }

  receive() external payable {}

  function deposit(uint256 amount) external {
    require(!ended, "Presale is finished");
    USDC.transferFrom(msg.sender, address(this), amount);
    balances[msg.sender] += amount;
    totalRaised += amount;
  }

  function claim() external nonReentrant {
    require(ended, "Presale is not ended");
    uint256 tokenReceive = claimableAmount(msg.sender);
    pkxToken.transfer(msg.sender, tokenReceive);
  }

  function claimableAmount(address account) public view returns (uint256) {
    return tokenSaleAmount * balances[account] / totalRaised;
  }

  function withdrawUSDC() external onlyOwner {
    uint256 amount = USDC.balanceOf(address(this));
    USDC.transfer(msg.sender, amount);
  }

  function withdrawPKX(uint256 amount) external onlyOwner {
    pkxToken.transfer(msg.sender, amount);
  }
}
