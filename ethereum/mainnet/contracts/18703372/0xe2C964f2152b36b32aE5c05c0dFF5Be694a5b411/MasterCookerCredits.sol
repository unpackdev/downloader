// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MasterCookerCredits {
    address public owner;
    uint256 public creditRate; // wei per credit
    mapping(string => uint256) public credits;

    // Events
    event CreditsPurchased(string indexed user, uint256 amount, uint256 creditsBought);
    event Withdrawn(address indexed owner, uint256 amount);
    event CreditRateChanged(uint256 newRate);

    constructor(uint256 _creditRate) {
        owner = msg.sender;
        creditRate = _creditRate;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    // ethAmount is an argument to avoid possibility of the contract owner front-running the user to change the creditRate
    function buyCredits(string memory user, uint256 ethAmount, uint256 creditsToBuy) external payable {
        require(msg.value > 0, "You must send ETH to buy credits.");
        require(msg.value == ethAmount, "ETH amount sent does not match the specified amount.");
        require(creditRate == (ethAmount / creditsToBuy), "ethAmount and creditsToBuy mismatch with rate");

        credits[user] += creditsToBuy;

        emit CreditsPurchased(user, ethAmount, creditsToBuy);

    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(owner).transfer(amount);

        emit Withdrawn(owner, amount);
    }

    function setCreditRate(uint256 newRate) external onlyOwner {
        creditRate = newRate;
        emit CreditRateChanged(newRate);
    }

    function getCreditBalance(string memory user) external view returns (uint256) {
        return credits[user];
    }
}