// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";

contract FundDeposit {

    address owner;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    mapping (address => bool) private whiteListedUsers;
    mapping (address => uint) maxUserDeposit;
    mapping (address => uint) private userBalance;

    event Deposit(address indexed user, uint amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can access");
        _;
    }

    /// @notice only whitelisted users can deposit the funds
    fallback() external payable {
        require(whiteListedUsers[msg.sender], "user is not in whitelist");
        require(msg.value != 0 && (msg.value + userBalance[msg.sender]) <= maxUserDeposit[msg.sender], "amount should be more than zero and less than the reserved amount");
        userBalance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function whiteListUser(address user, uint maxAmount) external onlyOwner {
        whiteListedUsers[user] = true;
        maxUserDeposit[user] = maxAmount;
    }

    function balance(address user) external view onlyOwner returns (uint) {
        return userBalance[user];
    }

    function withdraw() external onlyOwner {
        if(address(this).balance != 0){
            (bool success, ) = payable(owner).call{value: address(this).balance}("");
            require(success, "withdrawal failed");
        }
        uint usdcBalance = IERC20(USDC).balanceOf(address(this));
        if(usdcBalance != 0){
            bool success = IERC20(USDC).transfer(owner, usdcBalance);
            require(success, "USDC withdrawal failed");
        }
    }
}