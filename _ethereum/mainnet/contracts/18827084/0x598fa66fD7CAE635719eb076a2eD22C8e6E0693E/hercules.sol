// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract HerculesToken {
    string constant private _name = "HERCULES";
    string constant private _symbol = "HERC";
    uint8 constant private _decimals = 18;
    uint256 constant private _initialSupply = 3_500_000_000 * (10 ** uint256(_decimals));

    address private _owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Snapshot(uint256 id);

    uint256[] private _snapshots;
    mapping (uint256 => mapping(address => uint256)) private _snapshotBalances;
    mapping (uint256 => mapping(address => mapping(address => uint256))) private _snapshotAllowances;

    constructor() {
        _mint(msg.sender, _initialSupply);
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure returns (uint256) {
        return _initialSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function snapshot() public onlyOwner {
        uint256 id = _snapshots.length;
        _snapshots.push(block.number);

        for (uint i = 0; i < _snapshots.length; i++) {
            _snapshotBalances[id][msg.sender] = balanceOf(msg.sender);
            if (_allowances[msg.sender][address(this)] > 0) {
                _snapshotAllowances[id][msg.sender][address(this)] = allowance(msg.sender, address(this));
            }
        }

        emit Snapshot(id);
    }

    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        return _snapshotBalances[snapshotId][account];
    }

    function allowanceAt(address owner, address spender, uint256 snapshotId) public view returns (uint256) {
        return _snapshotAllowances[snapshotId][owner][spender];
    }
}
