// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract PSDAPresale is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  /// @notice Event emitted when user purchased the tokens.
  event Purchased(address user, uint256 amount, uint256 total);

  IERC20 private daiToken;

  address public multiSig;

  uint256 public startingTime;
  uint256 public maxDaiPerInvestor;
  uint256 public maxDai;
  uint256 public totalDai;

  mapping(address => uint256) public presaleCounter;

  modifier isValidAddress(address _address) {
    require(_address != address(0), "pSDA Presale: INVALID ADDRESS");
    _;
  }

  constructor(
    address _daiToken,
    address _multiSig,
    uint256 _startingTime,
    uint256 _maxDaiPerInvestor,
    uint256 _maxDai,
    uint256 _totalDai
  ) isValidAddress(_daiToken) isValidAddress(_multiSig) {
    daiToken = IERC20(_daiToken);
    multiSig = _multiSig;
    maxDaiPerInvestor = _maxDaiPerInvestor;
    startingTime = _startingTime;
    maxDai = _maxDai;
    totalDai = _totalDai;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  /**
   * @dev External function to set starting time. This function can be called only by owner.
   */
  function setStartingTime(uint256 _newTime) external onlyOwner {
    startingTime = _newTime;
  }

  function setTotalDai(uint256 _totalDai) external onlyOwner {
    totalDai = _totalDai;
  }

  /**
   * @dev External function to set starting time. This function can be called only by owner.
   */
  function setMultiSigAdddress(address _newAddress) external onlyOwner {
    multiSig = _newAddress;
  }

  function purchase(uint256 _amount) external callerIsUser nonReentrant {
    require(block.timestamp >= startingTime, "Not time to purchase");
    require(
      presaleCounter[msg.sender] + _amount <= maxDaiPerInvestor,
      "Exceeded max value to purchase"
    );
    require(totalDai + _amount <= maxDai, "Purchase would exceed max DAI");
    require(_amount <= daiToken.balanceOf(msg.sender), "pSDA Presale: INSUFFICIENT TOKEN BALANCE");
    require(
      _amount <= daiToken.allowance(msg.sender, address(this)),
      "pSDA Presale: INSUFFICIENT ALLOWANCE"
    );
    daiToken.transferFrom(msg.sender, multiSig, _amount);

    presaleCounter[msg.sender] += _amount;
    totalDai += _amount;
    emit Purchased(msg.sender, _amount, totalDai);
  }
}
