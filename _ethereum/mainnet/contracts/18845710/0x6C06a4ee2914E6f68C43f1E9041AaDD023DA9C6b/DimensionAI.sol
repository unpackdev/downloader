/*
  Website:       https://www.dimensionai.io/
  Telegram:      https://t.me/dimensionportal
  Docs:          https://docs.dimensionai.io/
  Twitter:       https://twitter.com/DimensionAIeth
  Medium:        https://medium.com/@dimensionai
  ENS:           dimensionai.eth
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./UniswapHelper.sol";

contract DimensionAI is UniswapHelper {

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  string public name = "DimensionAI";
  string public symbol = "DIM";

  uint8 public decimals = 18;
  uint public totalSupply = 1_000_000 * 10 ** decimals;

  mapping(address => mapping(address => uint)) public allowance;
  mapping(address => uint) public balanceOf;

  uint256 public maxBuyPercentage = 100; // 1%
  uint256 public buyTax = 200; // 2%

  address public owner;
  address public pair;
  bool public tradingLive;

  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
  }

  constructor () {
    owner = msg.sender;
    balanceOf[owner] += totalSupply;
    emit Transfer(address(0), owner, totalSupply);
  }

  // ERC20 BASIC //

  function transfer(address recipient, uint amount) external returns (bool) {
    require(tradingLive);

    balanceOf[msg.sender] -= amount;

    if (msg.sender == pair) {

      uint amountNoFee = _enforceTax(msg.sender, amount);
      balanceOf[recipient] += amountNoFee;

      uint maxWalletSupply = getMaxWalletSupply();
      require(maxWalletSupply >= balanceOf[recipient]);

      emit Transfer(msg.sender, recipient, amountNoFee);

    } else {

      balanceOf[recipient] += amount;
      emit Transfer(msg.sender, recipient, amount);

    }

    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool) {
    if (sender == address(this)) return _uniswapTransferFrom(recipient, amount);

    allowance[sender][msg.sender] -= amount;
    balanceOf[sender] -= amount;
    balanceOf[recipient] += amount;
    emit Transfer(sender, recipient, amount);
    return true;
  }

  function approve(address spender, uint amount) external returns (bool) {
    allowance[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  // BUY HELPERS //

  function _enforceTax(address sender, uint amount) private returns (uint) {
    uint256 _fee = amount * buyTax / 10000;
    balanceOf[address(this)] += _fee;
    emit Transfer(sender, address(this), _fee);

    return amount - _fee;
  }

  function getMaxWalletSupply() public view returns (uint) {
    return totalSupply * maxBuyPercentage / 10000;
  }

  // SELL HELPERS //
  
  function _uniswapTransferFrom(address recipient, uint amount) private returns (bool) {
    allowance[address(this)][msg.sender] -= amount;
    balanceOf[recipient] += amount;
    emit Transfer(address(this), recipient, amount);
    return true;
  }

  // TAX COLLECTOR //

  function collectTaxes() public {

    uint balance = balanceOf[address(this)];
    require(balance > 0);

    uint amountOut = _swap(balance);
    
    IWETH(WETH).withdraw(amountOut);

    uint reward = amountOut / 10000; // 0.01%
    (bool sent, ) = msg.sender.call{value: reward}("");
    require(sent, "Failed to send Ether");

    balanceOf[address(this)] = 0;

  }

  // OWNER //

  function enableTrading(address _pair) public onlyOwner {
    tradingLive = true;
    pair = _pair;
  }

  function upgradeParameters(uint256 _buyTax, uint256 _maxBuyPercentage) public onlyOwner {
    buyTax = _buyTax;
    maxBuyPercentage = _maxBuyPercentage;
  }

  function changeOwner(address _owner) public onlyOwner {
    owner = _owner;
  }

  function saveEther() public onlyOwner {
    (bool sent, ) = msg.sender.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }

  function saveToken(address token) public onlyOwner {
    uint256 amount = IERC20(token).balanceOf(address(this));
    IERC20(token).transfer(msg.sender, amount);
  }

}
