// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

contract HAMICoin is IERC20 {
    string public constant name = "HAMI";
    string public constant symbol = "HAMI";
    uint8 public constant decimals = 18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply = 69420000000000000 * 10**uint(decimals);
    address private feeAddress = 0x4977875020D70B453c069530F611DA126DB46677;
    uint256 public constant feePercent = 8;

    constructor() {
        // Distribute initial supply
        _balances[0xE10B38bbe359656066b3c4648DfEa7018711c35f] = _totalSupply * 10 / 100; // 10%
        _balances[msg.sender] = _totalSupply - _balances[0xE10B38bbe359656066b3c4648DfEa7018711c35f];
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint) {
        return _allowed[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowed[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from], "Insufficient balance");
        require(to != address(0), "Invalid address");

        uint256 fee = value * feePercent / 100;
        uint256 tokensToTransfer = value - fee;

        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + tokensToTransfer;
        _balances[feeAddress] = _balances[feeAddress] + fee;

        emit Transfer(from, to, tokensToTransfer);
        emit Transfer(from, feeAddress, fee);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0), "Invalid address");
        require(owner != address(0), "Invalid address");

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}