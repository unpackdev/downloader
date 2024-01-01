// Sources flattened with hardhat v2.18.3 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/Context.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File @openzeppelin/contracts/interfaces/IERC20.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;


// File contracts/Dexton.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;
interface IUSDT {
    function transferFrom(address _from, address _to, uint _value) external;
    function allowance(address _owner, address _spender) external returns (uint remaining);
    function balanceOf(address _owner) external view returns (uint256);
}

contract DEXTON is IERC20, Ownable(msg.sender) {

  mapping(address => uint256) public possessionTime;
  mapping(address => uint256) public _frozenBalances;
  mapping(address => uint256) _balances;
  mapping(address => uint256) _rewards;
  mapping(address => uint256) _depositedTime;
  mapping(address => uint8) _months;
  mapping(address => bool) _isDepositor;

  mapping (address => mapping (address => uint256)) _allowances;
  
  address constant TEAM_WALLET = 0x88a6BCc5e06Fb3150a596392afEF3d4e1188471c;
  address public usdtAddress;
  address[] depositors;
  uint256 public startTimestamp;
  uint256 public tokenPriceInUSDT;
  uint256 _totalSupply;
  uint256 _maxSupply;
  uint256 _lockedTokensForSixMonth;
  uint256 _rewardTokens;
  uint256 _tokensForPresale;
  uint8 interestOnDeposit;
  uint8 public decimals;
  string public symbol;
  string public name;

  event DEPOSIT(address sender, uint256 amount);
  event PRESALED(address buyer, uint256 amount);

  constructor() {
    name = "DEXTON";
    symbol = "DEXTON";
    decimals = 18;
    _totalSupply = 1000000000 * 1e18;
    _maxSupply = _totalSupply;
    usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    tokenPriceInUSDT = 1000000000000000;
    interestOnDeposit = 10;
    startTimestamp = block.timestamp;
    _tokensForPresale = _totalSupply / 20; 
    _lockedTokensForSixMonth = _totalSupply / 10;
    _rewardTokens = _totalSupply / 10;
    _balances[TEAM_WALLET] = _totalSupply / 2;
    _balances[address(this)] = _rewardTokens;

    emit Transfer(address(0), address(this), _rewardTokens);
    emit Transfer(address(0), TEAM_WALLET, _totalSupply/2);
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address _account) external view returns (uint256) {
    return _balances[_account];
  }

  function allowance(address _owner, address _spender) external view returns (uint256) {
    return _allowances[_owner][_spender];
  }

  function transfer(address _recipient, uint256 _amount) external returns (bool) {
    _transfer(msg.sender, _recipient, _amount);
    return true;
  }

  function approve(address _spender, uint256 _amount) external returns (bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool) {
    require(_allowances[_sender][msg.sender] - _amount > 0, "DEXTON: transfer amount exceeds allowance");

    _transfer(_sender, _recipient, _amount);
    _approve(_sender, msg.sender, _allowances[_sender][msg.sender] - _amount);
    return true;
  }

  function burn(uint256 _amount) public returns (bool) {
    _burn(msg.sender, _amount);
    return true;
  }

  function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
    _approve(msg.sender, _spender, _allowances[msg.sender][_spender] + _addedValue);
    return true;
  }

  function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
    _approve(msg.sender, _spender, _allowances[msg.sender][_spender] - _subtractedValue);
    return true;
  }

  function buyTokensByPresale(uint256 _amount) public {
    require(_tokensForPresale - _amount * 1e18 >= 0, "DEXTON: presale finished");
    require(IUSDT(usdtAddress).allowance(msg.sender, address(this)) >= tokenPriceInUSDT * _amount, "DEXTON: User has not given enough allowance"); //Checking Allowance in USDT Contract
    require(IUSDT(usdtAddress).balanceOf(msg.sender) >= tokenPriceInUSDT * _amount, "DEXTON: Insufficient user token balance");

    IUSDT(usdtAddress).transferFrom(msg.sender, TEAM_WALLET, _amount * tokenPriceInUSDT);
    _transfer(TEAM_WALLET, msg.sender, _amount * 1e18);
    _tokensForPresale -= _amount * 1e18;
    possessionTime[msg.sender] = block.timestamp;
    emit PRESALED(msg.sender, _amount);
  }

  function deposit(uint256 _amount) external {
    require(_balances[address(this)] > 0, "DEXTON: cann't deposit");
    require(_balances[msg.sender] >= _amount * 1e18, "DEXTON: insufficient token balance");
    
    update();
    _freezeTokens(msg.sender, _amount * 1e18); 
    if (_isDepositor[msg.sender] == false) {
      _isDepositor[msg.sender] == true;
      depositors.push(msg.sender);
    }
    emit DEPOSIT(msg.sender, _amount);
  }

  function withdraw() external {
    require(_balances[address(this)] == 0, " DEXTON: can not unfreeze tokens");
    uint256 depositorsLength = depositors.length;
    for(uint256 i; i < depositorsLength; ++i) {
      _unfreezeTokens(depositors[i], _frozenBalances[depositors[i]]);
    }
  }

  function claim() external {
    require(_isDepositor[msg.sender] == true, " DEXTON: you are not a depositor");
    require(_balances[address(this)] != 0, "DEXTON: cann't claim");
    require(_depositedTime[msg.sender] + 30 days < block.timestamp, "DEXTON: not time for claim");
    require(_months[msg.sender] <= 12, "DEXTON: deposit time was expired");

    update();
    if(_rewards[msg.sender] > 0) {
      _transfer(address(this), msg.sender, _rewards[msg.sender]);
      ++_months[msg.sender];
    }
  }

  function unlockTokens() external onlyOwner {
    require(startTimestamp + 180 days < block.timestamp, "DEXTON: cann't unlock");
    _balances[TEAM_WALLET] += _lockedTokensForSixMonth;
    startTimestamp = block.timestamp;
    emit Transfer(address(0), TEAM_WALLET, _totalSupply / 2);
  }

  function _transfer(address _sender, address _recipient, uint256 _amount) internal {
    require(_balances[_sender] - _frozenBalances[_sender] >= _amount, "DEXTON: insufficient token balance");
    require(_sender != address(0), "DEXTON: transfer from the zero address");
    require(_recipient != address(0), "DEXTON: transfer to the zero address");

    _balances[_sender] = _balances[_sender] - _amount;
    _balances[_recipient] = _balances[_recipient] + _amount;
    emit Transfer(_sender, _recipient, _amount);
  }

  function _burn(address _account, uint256 _amount) internal {
    require(_account != address(0), "DEXTON: burn from the zero address");
    require(_balances[_account] > 0, "DEXTON: transfer amount exceeds allowance");

    _balances[_account] = _balances[_account] - _amount;
    _totalSupply = _totalSupply - _amount;
    emit Transfer(_account, address(0), _amount);
  }

  function _approve(address _owner, address _spender, uint256 _amount) internal {
    require(_owner != address(0), "DEXTON: approve from the zero address");
    require(_spender != address(0), "DEXTON: approve to the zero address");

    _allowances[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }

  function _freezeTokens(address _user, uint256 _amount) private {
    require(_balances[_user] >= _amount, "DEXTON: user does not have enough tokens to freeze");
        
    _frozenBalances[_user] += _amount;
  }

  function _unfreezeTokens(address _user, uint256 _amount) private {
    require(_frozenBalances[_user] >= _amount, "DEXTON: not enough frozen tokens to unfreeze");
      
    _frozenBalances[_user] -= _amount;
  }

  function update() private {
    uint256 rewardAmount = ((block.timestamp - _depositedTime[msg.sender]) / 1 days) * (_frozenBalances[msg.sender]) / 30 / interestOnDeposit / 12;
    _rewards[msg.sender] += rewardAmount;
    _depositedTime[msg.sender] = block.timestamp;
  }
}