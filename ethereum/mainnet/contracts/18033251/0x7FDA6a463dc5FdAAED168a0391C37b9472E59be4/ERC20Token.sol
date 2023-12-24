// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20Token {
    string public name = "Qmusic.ai";
    string public symbol = "QMC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000000 * 10 ** uint256(decimals); // 100억 개

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public lockedBalance;
    mapping(address => uint256) public lockEndTime;
    mapping(address => bool) public isMinter;
    bool public paused = false;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Lock(address indexed account, uint256 value, uint256 endTime);
    event Unlock(address indexed account, uint256 value);
    event Pause();
    event Unpause();

    modifier whenNotPaused() {
        require(!paused, "Token transfers are paused");
        _;
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender], "Only designated minters can perform this action");
        _;
    }

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        isMinter[msg.sender] = true;
    }

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) public whenNotPaused returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint256 value) public whenNotPaused returns (bool) {
        require(from != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Burn(from, value);
        return true;
    }

    function mint(address to, uint256 value) public onlyMinter whenNotPaused returns (bool) {
        require(to != address(0), "Invalid address");
        require(value > 0, "Value must be greater than 0");
        
        totalSupply += value;
        balanceOf[to] += value;
        emit Mint(to, value);
        return true;
    }

    function lock(address account, uint256 amount, uint256 endTime) public onlyMinter whenNotPaused returns (bool) {
        require(account != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf[account] >= amount, "Insufficient balance");
        
        balanceOf[account] -= amount;
        lockedBalance[account] += amount;
        lockEndTime[account] = endTime;
        emit Lock(account, amount, endTime);
        return true;
    }

    function unlock(address account, uint256 amount) public onlyMinter whenNotPaused returns (bool) {
        require(account != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        require(lockedBalance[account] >= amount, "Insufficient locked balance");
        
        lockedBalance[account] -= amount;
        balanceOf[account] += amount;
        emit Unlock(account, amount);
        return true;
    }

    function designateMinter(address newMinter) public onlyMinter {
        isMinter[msg.sender] = false;
        isMinter[newMinter] = true;
    }

    function pause() public onlyMinter {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyMinter {
        paused = false;
        emit Unpause();
    }
}