// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";

contract AnjingInu is Context, IERC20, Ownable {
  using Address for address;
  using SafeMath for uint256;

  mapping(address => uint256) private _rOwned; // token owned adjust by rate
  mapping(address => uint256) private _tOwned; // token owned
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) private _isExcluded;
  address[] private _excluded;

  address private constant BURN_ADDR =
    0x000000000000000000000000000000000000dEaD;

  uint256 private constant MAX = ~uint256(0);
  uint256 private constant _tTotal = 100 * 10**6 * 10**9;
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;

  bool private _initialized = false;

  constructor() {
    _rOwned[_msgSender()] = _rTotal;
    emit Transfer(address(0), _msgSender(), _tTotal);
  }

  function initialize() external onlyOwner() {
    require(!_initialized, "Contract already initialized.");

    excludeAccount(owner());
    excludeAccount(BURN_ADDR);

    assert(_isExcluded[owner()]);
    assert(_isExcluded[BURN_ADDR]);

    _initialized = true;
  }

  function name() external pure returns (string memory) {
    return "Anjing Inu";
  }

  function symbol() external pure returns (string memory) {
    return "ANJING";
  }

  function decimals() external pure returns (uint8) {
    return 9;
  }

  function totalSupply() external pure override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) external view override returns (uint256) {
    require(_initialized, "Contract has not been initialized.");

    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount)
    external
    override
    returns (bool)
  {
    require(_initialized, "Contract has not been initialized.");

    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    external
    view
    override
    returns (uint256)
  {
    require(_initialized, "Contract has not been initialized.");

    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    external
    override
    returns (bool)
  {
    require(_initialized, "Contract has not been initialized.");

    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    require(_initialized, "Contract has not been initialized.");

    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    external
    virtual
    returns (bool)
  {
    require(_initialized, "Contract has not been initialized.");

    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    virtual
    returns (bool)
  {
    require(_initialized, "Contract has not been initialized.");

    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
    return true;
  }

  function isExcluded(address account) external view returns (bool) {
    require(_initialized, "Contract has not been initialized.");

    return _isExcluded[account];
  }

  function totalFees() external view returns (uint256) {
    require(_initialized, "Contract has not been initialized.");

    return _tFeeTotal;
  }

  function reflect(uint256 tAmount) external {
    require(_initialized, "Contract has not been initialized.");

    address sender = _msgSender();
    require(
      !_isExcluded[sender],
      "Excluded addresses cannot call this function"
    );
    (uint256 rAmount, , , , ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rTotal = _rTotal.sub(rAmount);
    _tFeeTotal = _tFeeTotal.add(tAmount);
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
    external
    view
    returns (uint256)
  {
    require(_initialized, "Contract has not been initialized.");
    require(tAmount <= _tTotal, "Amount must be less than supply");
    if (!deductTransferFee) {
      (uint256 rAmount, , , , ) = _getValues(tAmount);
      return rAmount;
    } else {
      (, uint256 rTransferAmount, , , ) = _getValues(tAmount);
      return rTransferAmount;
    }
  }

  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    require(rAmount <= _rTotal, "Amount must be less than total reflections");
    uint256 currentRate = _getRate();
    return rAmount.div(currentRate);
  }

  /**
   * excluded accounts don't generate rewards
   * exclude the following: contract address, uniswap address
   */
  function excludeAccount(address account) public onlyOwner() {
    require(!_isExcluded[account], "Account is already excluded");
    if (_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  function includeAccount(address account) external onlyOwner() {
    require(_isExcluded[account], "Account is not excluded");
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _tOwned[account] = 0;
        _isExcluded[account] = false;
        _excluded.pop();
        break;
      }
    }
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(
      amount >= 1000,
      "Transfer amount must be greater than or equal to 1000"
    );

    uint256 burnAmount = amount.div(100).mul(2);
    uint256 remainder = amount - burnAmount;

    // burn 2%
    _transferToExcluded(sender, BURN_ADDR, burnAmount);

    if (_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferFromExcluded(sender, recipient, remainder);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
      _transferToExcluded(sender, recipient, remainder);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
      _transferBothExcluded(sender, recipient, remainder);
    } else {
      _transferStandard(sender, recipient, remainder);
    }
  }

  function _transferStandard(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee
    ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferToExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee
    ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferFromExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee
    ) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferBothExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee
    ) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
  }

  function _getValues(uint256 tAmount)
    private
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
    uint256 currentRate = _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
      _getRValues(tAmount, tFee, currentRate);
    return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
  }

  /**
   * tValues are sender specific. Like transfer amount to an account
   */
  function _getTValues(uint256 tAmount)
    private
    pure
    returns (uint256, uint256)
  {
    uint256 tFee = tAmount.div(100).mul(2); // 2% fee on transfer
    uint256 tTransferAmount = tAmount.sub(tFee);
    return (tTransferAmount, tFee);
  }

  /**
   * r values are adjusted by the current rate which dynamically changes
   * based on changes to the rSupply and totalSupply
   */
  function _getRValues(
    uint256 tAmount,
    uint256 tFee,
    uint256 currentRate
  )
    private
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee);
    return (rAmount, rTransferAmount, rFee);
  }

  function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
        return (_rTotal, _tTotal);
      rSupply = rSupply.sub(_rOwned[_excluded[i]]);
      tSupply = tSupply.sub(_tOwned[_excluded[i]]);
    }
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }
}
