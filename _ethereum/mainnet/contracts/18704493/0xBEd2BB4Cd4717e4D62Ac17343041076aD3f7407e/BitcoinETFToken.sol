// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC20 {

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _transferOwnership(_msgSender());
  }

  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

contract BitcoinETFToken is Context, IERC20Metadata, Ownable {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private constant _decimals = 18;
  uint256 public burnPercentage = 5;
  uint256 public constant presaleReserve = 7200000000 * (10 ** _decimals);
  uint256 public constant stakingReserve = 2500000000 * (10 ** _decimals);
  uint256 public constant cexListReserve = 200000000 * (10 ** _decimals);
  uint256 public constant airdropReserve = 100000000 * (10 ** _decimals);

  mapping(address => bool) public isWhitelisted;
  event BurnPercentageChanged(uint256 oldBurnPercentage, uint256 newBurnPercentage, uint256 timestamp);

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
    _mint(0x853ffB780c52a23baFaaC23bb6Ffe2ec9f46635A, presaleReserve);
    _mint(0xb06a9665890406dB83802c07fF283345321B171b, stakingReserve);
    _mint(0x24e2e063572fC39FED2a648Ebb371E9c98a81108, cexListReserve);
    _mint(0xa133DA2DF519DB51f1BB911fb4f3346D4190f95B, airdropReserve);
  }

  function decreaseBurnPercentage(uint256 _burnPercentage) external onlyOwner {
    require(_burnPercentage >= 0 && _burnPercentage <= 5, 'unrecognised burn percentage');
    require(_burnPercentage < burnPercentage, 'New burn percentage must be less than current value');
    emit BurnPercentageChanged(burnPercentage, _burnPercentage, block.timestamp);
    burnPercentage = _burnPercentage;
  }

  function whitelistAddress(address _address, bool _status) external onlyOwner {
    isWhitelisted[_address] = _status;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    uint256 burnTax = isWhitelisted[_msgSender()] || isWhitelisted[recipient] ? 0 : ((amount * burnPercentage) / 100);
    if (burnTax > 0) _burn(_msgSender(), burnTax);
    _transfer(_msgSender(), recipient, amount - burnTax);
    return true;
  }

  function allowance(address from, address to) public view virtual override returns (uint256) {
    return _allowances[from][to];
  }

  function approve(address to, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), to, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    uint256 burnTax = isWhitelisted[sender] || isWhitelisted[recipient] ? 0 : ((amount * burnPercentage) / 100);
    if (burnTax > 0) _burn(sender, burnTax);
    _transfer(sender, recipient, amount - burnTax);
    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, 'ERC20: transfer amount exceeds allowance');
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

    return true;
  }

  function increaseAllowance(address to, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), to, _allowances[_msgSender()][to] + addedValue);
    return true;
  }

  function decreaseAllowance(address to, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][to];
    require(currentAllowance >= subtractedValue, 'ERC20: decreased allowance below zero');
    unchecked {
      _approve(_msgSender(), to, currentAllowance - subtractedValue);
    }

    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(amount > 0, 'ERC20: transfer amount zero');
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, 'ERC20: transfer amount exceeds balance');
    unchecked {
      _balances[sender] = senderBalance - amount;
    }
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
    unchecked {
      _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);
  }

  function burn(uint256 amount) external {
    _burn(_msgSender(), amount);
  }

  function _approve(address from, address to, uint256 amount) internal virtual {
    require(from != address(0), 'ERC20: approve from the zero address');
    require(to != address(0), 'ERC20: approve to the zero address');

    _allowances[from][to] = amount;
    emit Approval(from, to, amount);
  }
}