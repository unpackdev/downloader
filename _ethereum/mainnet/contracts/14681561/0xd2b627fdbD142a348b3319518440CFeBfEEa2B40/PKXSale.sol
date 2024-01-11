// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

import "./IUniswapV2Router02.sol";

contract PokerXSale is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  IERC20 public pkxToken = IERC20(0xEdff951a6Be79Ef4F00a034bB9FcD19b57bacBBF);

  uint256 public softcap = 30 * 10 ** 18;
  uint256 public tokenLiquidityAmount = 600000000000 * 10 ** 18;
  uint256 public tokenSaleAmount = 200000000000 * 10 ** 18;
  uint256 public totalRaised = 0;
  mapping(address => uint256) public balances;

  bool public ended = false;
  bool public claimable = false;
  bool public refundable = false;

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

  function startClaim() external onlyOwner {
    claimable = true;
  }

  function startRefund() external onlyOwner {
    refundable = true;
  }

  function _deposit(address account, uint256 amount) internal {
    require(!ended, "Presale is finished");
    balances[account] += amount;
    totalRaised += msg.value;
  }

  receive() external payable {
    _deposit(msg.sender, msg.value);
  }

  function deposit() external payable nonReentrant {
    _deposit(msg.sender, msg.value);
  }

  function claim() external nonReentrant {
    require(claimable, "Presale is not ended");
    uint256 tokenReceive = claimableAmount(msg.sender);
    pkxToken.transfer(msg.sender, tokenReceive);
  }

  function claimableAmount(address account) public view returns (uint256) {
    return tokenSaleAmount * balances[account] / totalRaised;
  }

  function getRefund() external nonReentrant {
    require(refundable, "Presale is not failed yet");
    payable(msg.sender).transfer(balances[msg.sender]);
  }

  function addLiquidity(uint256 ethAmount) external onlyOwner {
    // approve token transfer to cover all possible scenarios
    pkxToken.approve(address(uniswapV2Router), tokenLiquidityAmount);
    // add the liquidity
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(pkxToken),
      tokenLiquidityAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      msg.sender,
      block.timestamp
    );
  }

  function withdrawETH() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawPKX(uint256 amount) external onlyOwner {
    pkxToken.transfer(msg.sender, amount);
  }
}
