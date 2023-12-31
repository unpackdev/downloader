// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./Ownable.sol";

contract Migrate0xFree is Ownable {
    
    IERC20 public constant V1 = IERC20(0x2356F5F8f509D7827DF6742d27143689D118BffA);
    IERC20 public V2;
    bool public depositOpen = false;
    bool public withdrawalOpen = false;
    
    mapping(address => bool) public isBlacklisted;
    mapping(address => uint256) public claimable;
    mapping(address => uint256) public claimed;

    constructor() {}

    function V1Allowance(address _address) public view returns (uint256) {
        return V1.allowance(_address, address(this));
    }

    function V1Balance(address _address) public view returns (uint256) {
        return V1.balanceOf(_address);
    }

    function V2Balance(address _address) public view returns (uint256) {
        return V2.balanceOf(_address);
    }

    function setV2(address _V2) external onlyOwner {
        V2 = IERC20(_V2);
    }

    function openDeposit() external onlyOwner {
        depositOpen = true;
    }

    function closeDeposit() external onlyOwner {
        depositOpen = false;
    }

    function openWithdrawal() external onlyOwner {
        withdrawalOpen = true;
    }

    function closeWithdrawal() external onlyOwner {
        withdrawalOpen = false;
    }

    function addAddressesToBlacklist(address[] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            isBlacklisted[addresses[i]] = true;
        }
    }

    function removeAddressesFromBlacklist(address[] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            isBlacklisted[addresses[i]] = false;
        }
    }

    function deposit(uint256 amount) external {
        require(depositOpen, "Deposit is closed");
        require(V1.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        claimable[msg.sender] += amount;
    }

    function withdraw() external {
        require(withdrawalOpen, "Withdrawal is closed");
        require(!isBlacklisted[msg.sender], "Address is blacklisted");
        
        uint256 amount = claimable[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        
        require(V2.transfer(msg.sender, amount), "Transfer failed");
        claimable[msg.sender] = 0;
        claimed[msg.sender] += amount;
    }

    function withdrawAllV1() external onlyOwner {
        uint256 balance = V1.balanceOf(address(this));
        require(V1.transfer(owner(), balance), "Transfer failed");
    }

    function withdrawAllV2() external onlyOwner {
        uint256 balance = V2.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(V2.transfer(msg.sender, balance), "Withdraw Failed");
    }
}
