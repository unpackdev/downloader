// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract LorcPreSale is Ownable, Pausable {
  using SafeMath for uint256;

  IERC20 public lorcToken;
  IERC20 public usdtToken;
  uint public ethRate;
  uint public usdtRate;

  constructor(address _lorcToken, address _usdtToken, uint _ethRate, uint _usdtRate) {
      lorcToken = IERC20(_lorcToken);
      usdtToken = IERC20(_usdtToken);
      ethRate = _ethRate;
      usdtRate = _usdtRate;
  }

  /// @dev Update Exchange Rate for ETH to LORC
  function updateETHRate(uint _ethRate) external onlyOwner {
      require(_ethRate > 0, "LorcPreSale: rate must be greater than 0");
      ethRate = _ethRate;
  }

  /// @dev Update Exchange Rate for USDT to LORC
  function updateUSDTRate(uint _usdtRate) external onlyOwner {
      require(_usdtRate > 0, "LorcPreSale: rate must be greater than 0");
      usdtRate = _usdtRate;
  }

  /// @dev buy LORC with Ether
  function buyWithETH() external payable whenNotPaused returns(bool res) {
    require(msg.value > 0, "LorcPreSale: amount must be greater than 0");

    // Calculate the number of tokens to transfer
    uint lorcValue = msg.value.mul(ethRate);

    // Check Lorc balance in contract
    require(lorcToken.balanceOf(address(this)) >= lorcValue, "LorcPreSale: insufficient LORC Balance");

    // Transfer tokens to the sender
    require(lorcToken.transfer(msg.sender, lorcValue), "LorcPreSale: LORC Token Transfer failed");
    emit BuyLORCWithETH(msg.sender, address(lorcToken), lorcValue, ethRate);
    return true;
  }

  /// @dev buy LORC with USDT
  function buyWithUSDT(uint _usdtAmount) external whenNotPaused returns(bool res) {
    require(_usdtAmount > 0, "LorcPreSale: USDT amount must be greater than 0");

    // Calculate the number of tokens to transfer
    uint lorcValue = _usdtAmount.mul(usdtRate);

    require(lorcToken.balanceOf(address(this)) >= lorcValue, "LorcPreSale: insufficient LORC Balance");
    require(usdtToken.balanceOf(msg.sender) >= _usdtAmount, "LorcPreSale: insufficient USDT Balance");

    require(usdtToken.transferFrom(msg.sender, address(this), _usdtAmount), "LorcPreSale: Transfer failed");
    // Transfer tokens to the sender
    require(lorcToken.transfer(msg.sender, lorcValue), "LorcPreSale: LORC Token Transfer failed");

    emit BuyLORCWithUSDT(msg.sender, address(lorcToken), lorcValue, usdtRate);
    return true;
  }

  /// @dev withdraw ETH balance from contract to owner address
  function withdrawETH (uint _amount) external onlyOwner returns(bool res) {
    require(_amount <= address(this).balance, "LorcPreSale: insufficient ETH balance");
    payable(msg.sender).transfer(_amount);
    return true;
  }

  /// @dev withdraw ERC-20 balance from contract to owner address
  function withdrawErc20(IERC20 token) external onlyOwner returns(bool res) {
    uint256 _balance = token.balanceOf(address(this));
    require(_balance > 0, "LorcPreSale: insufficient ERC20 balance");
    require(token.transfer(msg.sender, _balance), "LorcPreSale: ERC20 transfer failed");
    return true;
  }

  /// @dev called by the owner to pause, triggers stopped state
  function pause() external onlyOwner whenNotPaused {
        _pause();
  }

  /// @dev called by the owner to unpause, returns to normal state
  function unpause() external onlyOwner whenPaused {
      _unpause();
  }

  receive() external payable {}
  event BuyLORCWithETH(address account, address token, uint amount, uint _ethRate);
  event BuyLORCWithUSDT(address account, address token, uint amount, uint _ethRate);
}