// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./Ownable.sol";

contract KpopCustomizingCoin is ERC20{
    address public owner;
    mapping(address => uint256) public lockupEndTime;
     uint8 private _decimals = 2;
    uint256 _totalSupply = 3000000000 * 10**uint256(_decimals); // 3 billion coins,
    

    constructor() ERC20("KPOP CUSTOMIZING COIN", "KCC") {
        owner = msg.sender;
        _mint(owner, _totalSupply);
    }    
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    function lockCoins(address account, uint256 amount, uint256 endTime) public onlyOwner {
        require(account != address(0), "Invalid address");
        require(endTime > block.timestamp, "End time must be in the future");
        require(balanceOf(account) >= amount, "Insufficient balance");

        lockupEndTime[account] = endTime;
        _transfer(account, address(this), amount);
    }
    function unlockCoins(address account) public onlyOwner {
        require(account != address(0), "Invalid address");
        require(lockupEndTime[account] > 0, "Account is not locked up");
        require(block.timestamp >= lockupEndTime[account], "Lockup period has not ended");

        uint256 lockedAmount = balanceOf(address(this));
        _transfer(address(this), account, lockedAmount);
        lockupEndTime[account] = 0;
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(lockupEndTime[msg.sender] == 0 || block.timestamp >= lockupEndTime[msg.sender], "Your coins are locked");
        return super.transfer(recipient, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(lockupEndTime[sender] == 0 || block.timestamp >= lockupEndTime[sender], "Sender's coins are locked");
        return super.transferFrom(sender, recipient, amount);
    }
}
