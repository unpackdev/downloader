// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Presale {
    address public owner;
    uint256 public maxCap;
    uint256 public currentAmount;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => uint256) public contributions;
    mapping(address => bool) public hasContributed;

    event Contribution(address indexed contributor, uint256 amount);
    event Withdrawal(address indexed receiver, uint256 amount);
    event Whitelisted(address indexed user, bool status);

    constructor() {
        owner = msg.sender;
        maxCap = 50 ether;
        currentAmount = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelistedAddresses[msg.sender] == true, "Your address is not whitelisted");
        _;
    }

    modifier withinCap(uint256 _amount) {
        require(currentAmount + _amount <= maxCap, "Amount exceeds the maximum cap");
        _;
    }

    modifier validContribution(uint256 _amount) {
        require(_amount >= 0.5 ether && _amount <= 1 ether, "Contribution should be between 0.5 and 1 ETH inclusive");
        _;
    }

    modifier firstContribution() {
        require(!hasContributed[msg.sender], "You can only contribute once");
        _;
    }

    function whitelistAddresses(address[] memory _addresses, bool _status) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelistedAddresses[_addresses[i]] = _status;
            emit Whitelisted(_addresses[i], _status);
        }
    }

    function contribute() public payable onlyWhitelisted withinCap(msg.value) validContribution(msg.value) firstContribution {
        contributions[msg.sender] += msg.value;
        currentAmount += msg.value;
        hasContributed[msg.sender] = true;
        emit Contribution(msg.sender, msg.value);
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        payable(owner).transfer(amount);
        emit Withdrawal(owner, amount);
    }
}