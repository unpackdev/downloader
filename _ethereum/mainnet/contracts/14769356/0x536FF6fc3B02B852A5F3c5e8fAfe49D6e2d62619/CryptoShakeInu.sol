// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract CryptoShakeInu is IERC20, ReentrancyGuard, Ownable {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  // private variables
  uint256 private _totalSupply;
  string private _name = "CryptoShakeInu";
  string private _symbol = "CSINU";
  uint8 private _decimals = 18;

  uint256 private _launchTime;
  address private _feeRecipeint;
  uint256 private _limitPeriod;

  // public variables
  uint256 public buyTax;
  uint256 public sellTax;
  address public dexPair;
  bool public enabled;
  IUniswapV2Router02 public dexRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  mapping (address => bool) public bots;

  uint256 public maxBuy;
  uint256 public maxWallet;

  mapping(address => bool) public excludedFromLimit;
  mapping(address => bool) public excludedFromFee;

  constructor(
    address _treasuryAddr,
    uint256 _total,
    uint256 _treasury,
    uint256 _buyTax,
    uint256 _sellTax,
    address _feeAddress,
    uint256 _limit
  ) {
    _totalSupply = _total;
    
    require(_treasury <= _totalSupply / 10, 'treasury should be less then 10% of total');

    _balances[msg.sender] = _totalSupply;

    maxBuy = _totalSupply * 2 / 100;
    maxWallet = _totalSupply * 3 / 100;

    buyTax = _buyTax;
    sellTax = _sellTax;
    _feeRecipeint = _feeAddress;
    _limitPeriod = _limit;

    IUniswapV2Factory factory = IUniswapV2Factory(dexRouter.factory());
    factory.createPair(address(this), dexRouter.WETH());
    dexPair = factory.getPair(address(this), dexRouter.WETH());

    excludedFromLimit[_msgSender()] = true;
    excludedFromFee[_msgSender()] = true;

    _register(_treasuryAddr, _treasury);

    emit Transfer(address(0), _msgSender(), _total);
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

  function updateFee(uint256 _buyFeeRate, uint256 _sellFeeRate) external onlyOwner {
    require(_buyFeeRate <= _totalSupply / 20 * 100);
    require(_sellFeeRate <= _totalSupply / 20 * 100);
    buyTax = _buyFeeRate;
    sellTax = _sellFeeRate;
  }

  function updateFeeAddress(address _address) external onlyOwner {
    _feeRecipeint = _address;
  }

  function updateLimitPeriod(uint256 _period) external onlyOwner {
    _limitPeriod = _period;
  }

  function removeBots(address _address) external onlyOwner {
    bots[_address] = false;
  }

  function enable() external onlyOwner {
    require(!enabled, 'already enabled');
    enabled = true;
    _launchTime = block.timestamp;
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

    // if buy
    if (_sender == dexPair) {
      if (block.timestamp < _launchTime + _limitPeriod && !excludedFromLimit[_recipient]) {
        require(_amount <= maxBuy, "exceeded max buy");
        require(_balances[_recipient] + _amount <= maxBuy, "exceeded max wallet");
      }
      if (!excludedFromFee[_recipient]) {
        uint256 fee = _amount * buyTax / 100;
        rAmount = _amount - fee;
        _balances[_feeRecipeint] += fee;
      }
    }
    // else if sell
    else if (_recipient == dexPair) {
      if (block.timestamp < _launchTime + _limitPeriod && !excludedFromLimit[_sender]) {
        require(_amount <= maxBuy, "exceeded max buy");
      }
      if (!excludedFromFee[_sender]) {
        uint256 fee = _amount * sellTax / 100;
        rAmount = _amount - fee;
        _balances[_feeRecipeint] += fee;
      }
    }
    // else then, i.e. token transferring, depositing or withdrawing from farms, taxes will not be applied
    _balances[_sender] = senderBalance - _amount;
    _balances[_recipient] += rAmount;

    emit Transfer(_sender, _recipient, _amount);
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

  // register treasury
  function _register(address _treasury, uint256 _amount) internal {
    _balances[_treasury] = _amount * 10 ** _decimals;
    excludedFromLimit[_treasury] = true;
    excludedFromFee[_treasury] = true;
  }
}
