// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Define the ERC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Crimingo is IERC20 {
    string public constant name = "Criminal Flamingo";
    string public constant symbol = "CRIMINGO";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100000000 * 10 ** uint256(decimals);
    uint256 public maxTokensHold = 100000000 * 10 ** uint256(decimals);
    uint256 public minTransactionAmount = 90000000 * 10 ** uint256(decimals);
    bool public isMinTransactionActive = true;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExemptedFromMaxHold;

    address private _owner;

    constructor() {
        _owner = msg.sender;
        _balances[_owner] = totalSupply;
        _isExemptedFromMaxHold[_owner] = true;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner can call this function");
        _;
    }

    modifier onlyDisableMinTransaction() {
        require(isMinTransactionActive, "Minimum transaction is already disabled");
        _;
    }

    function disableMinTransaction() external onlyOwner onlyDisableMinTransaction {
        isMinTransactionActive = false;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function setExemption(address user, bool value) public onlyOwner {
        _isExemptedFromMaxHold[user] = value;
    }

    function setMaxTokensHold(uint256 amount) public onlyOwner {
        maxTokensHold = amount;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        if (isMinTransactionActive) {
            require(amount >= minTransactionAmount, "Transaction amount below minimum");
        }

        if (!_isExemptedFromMaxHold[recipient]) {
            require(_balances[recipient] + amount <= maxTokensHold, "Max tokens hold limit reached");
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
}