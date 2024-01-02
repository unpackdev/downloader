// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract TokenSale is ReentrancyGuard, Ownable, Pausable {
  // USDT
  IERC20 public USDT;

  // Sale details
  uint public saleStart;
  uint public saleEnd;

  uint256 public constant etherUnit = 1 ether;

  // Round1
  uint256 public constant round1Price = 30000; // 0.030 per token
  uint256 public  round1Cap; // 10% tokens in round 1

  // Round2
  uint256 public  constant round2Price = 35000; // 0.035 per token
  uint256 public  round2Cap; // 10% tokens in round 2
  uint public round2Start;

  // Round3
  uint256 public constant round3Price = 40000; // 0.040 per token
  uint256 public  round3Cap; // 20% tokens in round 3
  uint public round3Start;

  // Track sale
  uint256 public totalTokensSold;

  // Limit per address
  uint256 public individualCap; // 0.5% per address

  mapping(address => uint256) public contributions;

  event Purchase(address indexed buyer, uint256 amount);

  /// @notice Constructor to initialize sale parameters
  /// @param _saleStart Start selling timestamp, measured in seconds.
  /// @param _usdt USDT.
  constructor(uint256 _saleStart, IERC20 _usdt, uint256 _totalSupply) Ownable(msg.sender) {
    saleStart = _saleStart;
    USDT = _usdt;
    round2Start = saleStart + 60 days;
    round3Start = round2Start + 60 days;
    saleEnd = round3Start + 60 days; // Sale open for 60 days after round3
    round1Cap = _totalSupply / 10;
    round2Cap = _totalSupply / 10;
    round3Cap = _totalSupply / 10 * 2;
    individualCap = _totalSupply * 5 / 1000;
  }

  /// @notice Buy tokens with token during sale
  /// @param _amount Number of tokens to purchase
  function buyTokens(uint256 _amount) nonReentrant whenNotPaused public {
    uint256 currentTimestamp = block.timestamp;

    require(currentTimestamp >= saleStart, "Sale not started");
    require(currentTimestamp <= saleEnd, "Sale ended");
    require(_amount >= 1 ether, "Less than the minimum amount");

    uint256 currentContribution = contributions[msg.sender];
    require(currentContribution + _amount <= individualCap, "Limit exceeded");

    // check the required amount.
    uint256 requiredTokens = checkRequiredTokens(currentTimestamp, _amount);

    contributions[msg.sender] = currentContribution + _amount;
    totalTokensSold = totalTokensSold + _amount;

    // fix round start time if end in advance
    updateRoundStartTimes(currentTimestamp, totalTokensSold);

    SafeERC20.safeTransferFrom(USDT, msg.sender, address(this), requiredTokens);

    emit Purchase(msg.sender, _amount);
  }

  function updateRoundStartTimes(uint256 currentTimestamp, uint256 currentTotalSold) private {
    if (currentTotalSold >= round1Cap && currentTimestamp < round2Start) {
      round2Start = currentTimestamp;
      round3Start = round2Start + 60 days;
      saleEnd = round3Start + 60 days;
    }
    if (currentTotalSold >= round1Cap + round2Cap && currentTimestamp < round3Start) {
      round3Start = currentTimestamp;
      saleEnd = round3Start + 60 days;
    }
    if (currentTotalSold >= round1Cap + round2Cap + round3Cap && currentTimestamp < saleEnd) {
      saleEnd = currentTimestamp;
    }
  }

  function checkRequiredTokens(uint256 _timestamp, uint256 _amount) private view returns (uint256 requiredTokens) {

    uint256 currentTotalSold = totalTokensSold;

    if (_timestamp < round2Start) {
      // Round 1
      require(currentTotalSold + _amount <= round1Cap, "Round 1 Cap exceeded");
      requiredTokens = round1Price * _amount / etherUnit;
    } else if (_timestamp < round3Start) {
      // Round 2
      require(currentTotalSold + _amount <= round1Cap + round2Cap, "Round 2 Cap exceeded");
      requiredTokens = round2Price * _amount / etherUnit;
    } else {
      // Round 3
      require(currentTotalSold + _amount <= round1Cap + round2Cap + round3Cap, "Round 3 Cap exceeded");
      requiredTokens = round3Price * _amount / etherUnit;
    }
  }

  /// @notice Get current round, price and remaining cap
  /// @return _round Current round number
  /// @return _roundPrice Token price for current round
  /// @return _remain Tokens remaining for sale in current round
  function round() public view returns (int8 _round, uint256 _roundPrice, uint256 _remain) {
    uint256 currentTimestamp = block.timestamp;
    if (currentTimestamp < saleStart) {
      _round = 0;
      _roundPrice = 0;
      _remain = 0;
    } else if (currentTimestamp < round2Start) {
      _round = 1;
      _roundPrice = round1Price;
      _remain = round1Cap - totalTokensSold;
    } else if (currentTimestamp < round3Start) {
      _round = 2;
      _roundPrice = round2Price;
      _remain = round1Cap + round2Cap - totalTokensSold;
    } else if (currentTimestamp < saleEnd) {
      _round = 3;
      _roundPrice = round3Price;
      _remain = round1Cap + round2Cap + round3Cap - totalTokensSold;
    } else {
      _round = - 1;
      _roundPrice = 0;
      _remain = 0;
    }
  }

  /// @notice  to withdraw ETH from contract
  /// @param _amount Withdraw amount.
  function withdrawETH(uint256 _amount) external onlyOwner {
    require(address(this).balance >= _amount, "Invalid Amount");
    payable(msg.sender).transfer(_amount);
  }

  /// @notice  to withdraw ERC20 tokens from contract
  /// @param _token Withdraw token address.
  /// @param _amount Withdraw token amount.
  function withdrawToken(IERC20 _token, uint256 _amount) external onlyOwner {
    require(_token.balanceOf(address(this)) >= _amount, "Invalid Amount");
    _token.transfer(msg.sender, _amount);
  }

  function pause() external onlyOwner {
    super._pause();
  }

  function unpause() external onlyOwner {
    super._unpause();
  }
}
