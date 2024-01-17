/*

  ____                          _
 / ___| _ __   __ _  ___ ___   / \   _ __   ___
 \___ \| '_ \ / _` |/ __/ _ \ / _ \ | '_ \ / _ \
  ___) | |_) | (_| | (_|  __// ___ \| |_) |  __/
 |____/| .__/ \__,_|\___\___/_/   \_\ .__/ \___|
       |_|                          |_|

SpaceApe Dividends 🐒+🍌=🚀→🌕

Designed to work around the existing SpaceApe contract (and its quirks), rather
than an ideal implementation. Dividend concepts based on EIP-2222.

$APED tokens tracked in this contract represent non-transferable dividend
shares. Shares provide points which can be exchanged to withdraw $WORM rewards.

🦄 Buy $APE on Uniswap @
https://app.uniswap.org/#/swap?outputCurrency=0x07bd9efbe87ba5ec52272a4fc0855e5b5b818b85&chain=mainnet

🐵 Get your rewards at https://app.spaceape.army

🌎 https://SpaceApe.army

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./ITokenDividendTracker.sol";

contract SpaceApeDividends is ERC20, Ownable, ReentrancyGuard, ITokenDividendTracker {
  /// Token which must be held for eligibility ($APE).
  IERC20 private constant _HOLDER_TOKEN = ERC20(0x07bD9efBe87Ba5EC52272A4fc0855E5B5B818b85);
  /// Token used to pay dividends ($WORM).
  IERC20 private constant _FUNDS_TOKEN = ERC20(0xF7Ecb2E5ddaD17506E62F51A442f725a26053fb2);
  /// Minimum amount of $APE held required to receive dividends.
  uint256 private constant _MINIMUM_BALANCE = 10**14; // 0.0001% of $APE total supply
  /// Magnitude points multiplier for dealing with small numbers.
  uint256 private constant _MAGNITUDE = 2**128;
  /// Pause dividend distribution and payout (withdrawals).
  bool private _paused = false;
  /// The total amount of dividend shares that have been distributed.
  uint256 private _totalDistributed;
  /// Rewards token pool balance ($WORM).
  uint256 private _fundsTokenBalance;
  /// Points per share (multiplied by _MAGNITUDE).
  uint256 private _pointsPerShare;
  /// Points correction for share balance changes (multiplied by _MAGNITUDE).
  mapping(address => int256) private _pointsCorrection;
  /// Total funds withdrawn per holder ($WORM).
  mapping(address => uint256) private _withdrawnFunds;
  /// Exclude address from receiving dividend shares.
  mapping(address => bool) private _excluded;

  event Withdraw(address indexed account, uint256 amount);
  event Paused(bool value);

  error NonTransferable();

  constructor() ERC20("SpaceApeDividends", "$APED") {}

  function _distribute(uint256 amount) private {
    require(totalSupply() > 0, "NO_SUPPLY");

    if (amount > 0) {
      _pointsPerShare += (amount * _MAGNITUDE) / totalSupply();
      _totalDistributed += amount;
    }
  }

  function _updateFundsTokenBalance() private returns (int256) {
    uint256 prevFundsTokenBalance = _fundsTokenBalance;
    _fundsTokenBalance = _FUNDS_TOKEN.balanceOf(address(this));

    return int256(_fundsTokenBalance) - int256(prevFundsTokenBalance);
  }

  function _updateFundsReceived() private {
    int256 newFunds = _updateFundsTokenBalance();

    if (newFunds > 0) {
      _distribute(uint256(newFunds));
    }
  }

  function _setBalance(address account, uint256 newBalance) private {
    uint256 balance = balanceOf(account);

    if (newBalance > balance) {
      if (newBalance >= _MINIMUM_BALANCE && !_excluded[account]) {
        _mint(account, newBalance - balance);
      }
    } else if (newBalance < balance) {
      _burn(account, balance - newBalance);
    }
  }

  function _transfer(address, address, uint256) internal pure override {
    revert NonTransferable();
  }

  function _mint(address account, uint256 amount) internal override {
    super._mint(account, amount);

    _pointsCorrection[account] -= int256(_pointsPerShare * amount);
  }

  function _burn(address account, uint256 amount) internal override {
    super._burn(account, amount);

    _pointsCorrection[account] += int256(_pointsPerShare * amount);
  }

  function _accumulativeFundsOf(address account) private view returns (uint256) {
    return uint256(int256(_pointsPerShare * balanceOf(account)) + _pointsCorrection[account]) / _MAGNITUDE;
  }

  function _withdrawableFundsOf(address account) private view returns (uint256) {
    return _accumulativeFundsOf(account) - _withdrawnFunds[account];
  }

  function _prepareWithdraw() private returns (uint256) {
    uint256 _withdrawableDividend = _withdrawableFundsOf(msg.sender);
    _withdrawnFunds[msg.sender] += _withdrawableDividend;
    emit Withdraw(msg.sender, _withdrawableDividend);

    return _withdrawableDividend;
  }

  function withdraw() external nonReentrant {
    require(!_paused, "PAUSED");

    uint256 withdrawableFunds = _prepareWithdraw();

    require(_FUNDS_TOKEN.transfer(msg.sender, withdrawableFunds), "TRANSFER_FAILED");

    _updateFundsTokenBalance();
  }

  function dividendsOf(address account) public view returns (
    uint256 withdrawable,
    uint256 paid
  ) {
    return (
      _withdrawableFundsOf(account),
      _withdrawnFunds[account]
    );
  }

  function stats() public view returns (
    uint256 totalDistributed,
    bool paused
  ) {
    return (
      _totalDistributed,
      _paused
    );
  }

  function _exclude(address account, bool excluded) private {
    _excluded[account] = excluded;

    if (excluded) {
      _setBalance(account, 0);
    } else {
      _setBalance(account, _HOLDER_TOKEN.balanceOf(account));
    }
  }

  function pause(bool paused) external onlyOwner {
    _paused = paused;
    emit Paused(paused);
  }

  /* Remap functions for compatibility with ITokenDividendTracker. */

  function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    if (_paused) return;

    _setBalance(account, newBalance);
  }

  function process(uint256) external returns (uint256, uint256, uint256) {
    // noop
  }

  function distributeTokenRewardDividends(uint256) external {
    _updateFundsReceived();
  }

  function excludeFromDividends(address account) external onlyOwner {
    _exclude(account, true);
  }

  function includeInDividends(address account) external onlyOwner {
    _exclude(account, false);
  }

  function isexcludeFromDividends(address account) external view returns (bool) {
    return _excluded[account];
  }

  /* Unclaimed shares functions to get owed shares e.g., for previous $APE balance. */

  function updateShares() external {
    require(!_paused, "PAUSED");

    _setBalance(msg.sender, _HOLDER_TOKEN.balanceOf(msg.sender));
  }

  function unclaimedSharesOf(address account) external view returns (uint256) {
    return _excluded[account] ? 0 : _HOLDER_TOKEN.balanceOf(account) - balanceOf(account);
  }
}

/// @dev 0xf09f8cb2
