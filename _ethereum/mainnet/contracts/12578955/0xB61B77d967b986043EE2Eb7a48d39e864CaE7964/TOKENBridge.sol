// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract TOKENBridge is ReentrancyGuard, Context, Ownable {
  using SafeMath for uint256;

  mapping (address => bool) private validators;

  address payable private feeAddress;
  uint256 private feeRate = 0;
  bool private isFrozen = false;
  uint256 private maxTransactionWSG = 30000000000000000000;  // 30
  uint256 private maxTransactionGASPAY = 75000000000000000000;  // 75
  uint256 private maxTransactionGASG = 150000000000000000000;  // 150

  IERC20 private WSG_TOKEN;
  IERC20 private GASPAY_TOKEN;
  IERC20 private GASG_TOKEN;

  constructor(address _WSGToken, address _GASPAYToken, address _GASGToken) {
    WSG_TOKEN = IERC20(_WSGToken);
    GASPAY_TOKEN = IERC20(_GASPAYToken);
    GASG_TOKEN = IERC20(_GASGToken);
  }

  event Exchange(address indexed user, uint256 amount, uint256 fee, string project);
  // event ExchangeWSG(address indexed user, uint256 amount, uint256 fee);
  // event ExchangeGASPAY(address indexed user, uint256 amount, uint256 fee);
  // event ExchangeGASG(address indexed user, uint256 amount, uint256 fee);

  function isValidator(address _addr) external view returns (bool) {
      return validators[_addr];
  }

  function addValidator(address _addr) external onlyOwner nonReentrant {
      validators[_addr] = true;        
  }

  function removeValidator(address _addr) external onlyOwner nonReentrant {
      if (validators[_addr]) {
          delete validators[_addr];
      }
  }

  function getFeeAddress() external view returns (address) {
    return feeAddress;
  }

  function setFeeAddress(address payable _feeAddress) external onlyOwner nonReentrant {
    require(_feeAddress != address(0), "Bad address");
    feeAddress = _feeAddress;
  }

  function getFeeRate() external view returns (uint256) {
    return feeRate;
  }

  function setFeeRate(uint256 _feeRate) external onlyOwner nonReentrant {
    feeRate = _feeRate;
  }

  function getMaxTransaction() external view returns (uint256 wsg, uint256 gaspay, uint256 gasg) {
    wsg = maxTransactionWSG;
    gaspay = maxTransactionGASPAY;
    gasg = maxTransactionGASG;
  }

  function setMaxTransactionWSG(uint256 _maxTransaction) external onlyOwner nonReentrant {
    require(_maxTransaction > 0, "Max transaction must be greater than 0");
    maxTransactionWSG = _maxTransaction;
  }

  function setMaxTransactionGASPAY(uint256 _maxTransaction) external onlyOwner nonReentrant {
    require(_maxTransaction > 0, "Max transaction must be greater than 0");
    maxTransactionGASPAY = _maxTransaction;
  }

  function setMaxTransactionGASG(uint256 _maxTransaction) external onlyOwner nonReentrant {
    require(_maxTransaction > 0, "Max transaction must be greater than 0");
    maxTransactionGASG = _maxTransaction;
  }

  function getFrozen() external view returns (bool) {
    return isFrozen;
  }

  function setFrozen(bool _isFrozen) external onlyOwner nonReentrant {
    isFrozen = _isFrozen;
  }

  function getTokenBalance() external view returns (uint256 wsg, uint256 gaspay, uint256 gasg) {
    wsg = WSG_TOKEN.balanceOf(address(this));
    gaspay = GASPAY_TOKEN.balanceOf(address(this));
    gasg = GASG_TOKEN.balanceOf(address(this));
  }

  function sweepWSGTokenBalance() external payable onlyOwner {
    uint256 amount2Pay = WSG_TOKEN.balanceOf(address(this));
    require(WSG_TOKEN.transfer(msg.sender, amount2Pay), "Unable to transfer funds");
  }

  function sweepGASPAYTokenBalance() external payable onlyOwner {
    uint256 amount2Pay = GASPAY_TOKEN.balanceOf(address(this));
    require(GASPAY_TOKEN.transfer(msg.sender, amount2Pay), "Unable to transfer funds");
  }

  function sweepGASGTokenBalance() external payable onlyOwner {
    uint256 amount2Pay = GASG_TOKEN.balanceOf(address(this));
    require(GASG_TOKEN.transfer(msg.sender, amount2Pay), "Unable to transfer funds");
  }

  function exchangeWSGToken(uint256 _amt) external payable nonReentrant {
    require(!isFrozen, "Contract is frozen");
    require(msg.value >= feeRate, "Fee not met");
    require(_amt > 0, "Amount must be greater than 0");
    require(WSG_TOKEN.allowance(msg.sender, address(this)) >= _amt, "Not enough allowance");
    feeAddress.transfer(msg.value);
    if(_amt > maxTransactionWSG) {
      require(WSG_TOKEN.transferFrom(msg.sender, address(this), maxTransactionWSG), "Unable to transfer funds");
      // emit ExchangeWSG(msg.sender, maxTransactionWSG, msg.value);
      emit Exchange(msg.sender, maxTransactionWSG, msg.value, 'WSG');
    } else {
      require(WSG_TOKEN.transferFrom(msg.sender, address(this), _amt), "Unable to transfer funds");
      // emit ExchangeWSG(msg.sender, _amt, msg.value);
      emit Exchange(msg.sender, _amt, msg.value, 'WSG');
    }
  }

  function exchangeGASPAYToken(uint256 _amt) external payable nonReentrant {
    require(!isFrozen, "Contract is frozen");
    require(msg.value >= feeRate, "Fee not met");
    require(_amt > 0, "Amount must be greater than 0");
    require(GASPAY_TOKEN.allowance(msg.sender, address(this)) >= _amt, "Not enough allowance");
    feeAddress.transfer(msg.value);
    if(_amt > maxTransactionGASPAY) {
      require(GASPAY_TOKEN.transferFrom(msg.sender, address(this), maxTransactionGASPAY), "Unable to transfer funds");
      // emit ExchangeGASPAY(msg.sender, maxTransactionGASPAY, msg.value);
      emit Exchange(msg.sender, maxTransactionGASPAY, msg.value, 'GASPAY');
    } else {
      require(GASPAY_TOKEN.transferFrom(msg.sender, address(this), _amt), "Unable to transfer funds");
      // emit ExchangeGASPAY(msg.sender, _amt, msg.value);
      emit Exchange(msg.sender, _amt, msg.value, 'GASPAY');
    }
  }

  function exchangeGASGToken(uint256 _amt) external payable nonReentrant {
    require(!isFrozen, "Contract is frozen");
    require(msg.value >= feeRate, "Fee not met");
    require(_amt > 0, "Amount must be greater than 0");
    require(GASG_TOKEN.allowance(msg.sender, address(this)) >= _amt, "Not enough allowance");
    feeAddress.transfer(msg.value);
    if(_amt > maxTransactionGASG) {
      require(GASG_TOKEN.transferFrom(msg.sender, address(this), maxTransactionGASG), "Unable to transfer funds");
      // emit ExchangeGASG(msg.sender, maxTransactionGASG, msg.value);
      emit Exchange(msg.sender, maxTransactionGASG, msg.value, 'GASG');
    } else {
      require(GASG_TOKEN.transferFrom(msg.sender, address(this), _amt), "Unable to transfer funds");
      // emit ExchangeGASG(msg.sender, _amt, msg.value);
      emit Exchange(msg.sender, _amt, msg.value, 'GASG');
    }
  }

}
