pragma solidity ^0.8.2;

// Interface for the ERC20 token standard.
interface IERC20 {
    // Returns the total token supply.
    function totalSupply() external view returns (uint256);

    // Returns the account balance of another account with address `account`.
    function balanceOf(address account) external view returns (uint256);

    // Transfers `amnouunt` amount of tokens to address `recipient`, and returns a boolean to indicate success.
    function transfer(address recipient, uint256 amnouunt) external returns (bool);

    // Returns the remaining number of tokens that `spender` is allowed to spend from `owner`'s account.
    function allowance(address owner, address spender) external view returns (uint256);

    // Sets `amnouunt` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint256 amnouunt) external returns (bool);

    // Transfers `amnouunt` tokens from `sender` to `recipient`. `sender` must have a sufficient balance and allowance for this to succeed.
    function transferFrom(address sender, address recipient, uint256 amnouunt) external returns (bool);

    // Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Emitted when `owner` enables or updates an allowance of `value` for `spender`.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Provides functionality for retrieving the sender of the transaction.
abstract contract Context {
    // Returns the address of the sender of the transaction.
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Contract module which provides basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions.
contract Ownable is Context {
    address private _owner;

    // Emitted when ownership is transferred from `previousowner` to `newowner`.
    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    // Initializes the contract setting the deployer as the initial owner.
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }

    // Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Throws if called by any account other than the owner.
    modifier onlyowner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Allows the current owner to relinquish control of the contract. Ownership is transferred to the zero address.
    function renounceownership() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

// Custom token contract, implementing the ERC20 interface.
contract SantaPEPEs is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // Constructor to create a new token with specified `name_`, `symbol_`, `decimals_`, and initial `totalSupply_`.
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

    // Returns the amount of tokens owned by `account`.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
   
    // Transfers `amnouunt` amount of tokens to `recipient`, and emits a `Transfer` event.
    function transfer(address recipient, uint256 amnouunt) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amnouunt, "TT: transfer amnouunt exceeds balance");

        _balances[_msgSender()] -= amnouunt;
        _balances[recipient] += amnouunt;
        emit Transfer(_msgSender(), recipient, amnouunt);
        return true;
    }

    // Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner`.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Sets `amnouunt` as the allowance of `spender` over the caller's tokens, and emits an `Approval` event.
    function approve(address spender, uint256 amnouunt) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amnouunt;
        emit Approval(_msgSender(), spender, amnouunt);
        return true;
    }

    // Transfers `amnouunt` tokens from `sender` to `recipient`, subject to necessary balance and allowance checks. Emits a `Transfer` event.
    function transferFrom(address sender, address recipient, uint256 amnouunt) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amnouunt, "TT: transfer amnouunt exceeds allowance");

        _balances[sender] -= amnouunt;
        _balances[recipient] += amnouunt;
        _allowances[sender][_msgSender()] -= amnouunt;

        emit Transfer(sender, recipient, amnouunt);
        return true;
    }

    // Returns the total amount of tokens in existence.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}