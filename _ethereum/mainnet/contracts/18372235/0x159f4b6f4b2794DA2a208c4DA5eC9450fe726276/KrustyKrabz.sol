// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract KrustyKrabz {
    string public name = "KrustyKrabz";
    string public symbol = "KRABZ";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100 * 10**6 * 10**18;

    address private _owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Staking variables
    mapping(address => uint256) private _stakes;
    mapping(address => uint256) private _rewards;
    uint256 public totalStaked;

    event Staked(address indexed user, uint256 amount, uint256 totalStaked);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor() {
        _owner = msg.sender;
        _balances[_owner] = totalSupply;
        emit Transfer(address(0), _owner, totalSupply);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

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

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "Cannot approve to the zero address");

        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "Cannot approve to the zero address");
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function stake(uint256 amount) public {
        _balances[msg.sender] -= amount;
        _stakes[msg.sender] += amount;
        totalStaked += amount;
        emit Staked(msg.sender, amount, totalStaked);
    }

    function withdraw(uint256 amount) public {
        _stakes[msg.sender] -= amount;
        _balances[msg.sender] += amount;
        totalStaked -= amount;
        emit Withdrawn(msg.sender, amount);
    }

    function reward(address user, uint256 rewardAmount) public onlyOwner {
        _rewards[user] += rewardAmount;
        emit RewardPaid(user, rewardAmount);
    }

    function myStake() public view returns (uint256) {
        return _stakes[msg.sender];
    }

    function myRewards() public view returns (uint256) {
        return _rewards[msg.sender];
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[sender] >= amount, "Transfer amount exceeds balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}