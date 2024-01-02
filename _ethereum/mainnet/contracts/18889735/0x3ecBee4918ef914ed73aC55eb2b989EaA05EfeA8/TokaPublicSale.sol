// SPDX-License-Identifier: MIT

pragma solidity =0.8.21;

import "./OwnableUpgradeable.sol";

contract TokaPublicSale is OwnableUpgradeable {
    uint256 public startTime;
    uint256 public endTime;

    address public tokaToken;

    uint256 public totalReceived;

    mapping(address => uint256) public userAmount;

    event Purchase(address indexed user, uint256 amount);

    function initialize() public initializer {
        __Ownable_init(msg.sender);
    }

    function setStartEndTime(uint256 _start, uint256 _end) external onlyOwner {
        startTime = _start;
        endTime = _end;
    }

    function purchase() external payable {
        require(block.timestamp >= startTime && startTime != 0, "Sale not started");
        require(block.timestamp <= endTime && endTime != 0, "Sale already ended");
        require(msg.value > 0, "Can not purchase zero");
        require(msg.value <= 5 ether, "more than 5 ether");

        userAmount[msg.sender] += msg.value;
        totalReceived += msg.value;

        emit Purchase(msg.sender, msg.value);
    }

    function settle() external onlyOwner {
        require(block.timestamp >= endTime, "Sale not started");

        // Settle total toka tokens allocated
    }

    function collect(address to) external onlyOwner {
        uint256 amount = address(this).balance;
        payable(to).transfer(amount);
    }

    event Refund(address indexed user, uint256 amount);

    function refund() external{
        require(block.timestamp < 1703822400, "Refund ends");
        uint256 amount = userAmount[msg.sender];

        require(amount > 0, "no fund available");
        require(amount <= address(this).balance, "less than quota");

        userAmount[msg.sender] = 0;
        totalReceived -= amount;

        payable(msg.sender).transfer(amount);
        emit Refund(msg.sender, amount);
    }

    // rollover to next round
    uint256 public totalRollover;
    mapping(address => uint256) public userRollover;

    event Rollover(address user, uint256 amount);

    bytes32 public desiredRollKey = 0xc30fad1d6bc07e9129a8ba2272b08aa9a44baff6bad0708e5244dbc2224f44e1;

    function rollOver(string memory key) external{
        // only tx from front end when round2 starts will proceed
        require(keccak256(abi.encodePacked(key)) == desiredKey, "wrong key");

        uint amount = userAmount[msg.sender];

        // deduct round1 info
        userAmount[msg.sender] = 0;
        totalReceived -= amount;

        // roll to next round, record the state
        userRollover[msg.sender] += amount;
        totalRollover += amount;

        emit Rollover(msg.sender, amount);

        // ETH reamins still in this contract
    }

    bytes32 public constant desiredKey = 0xc30fad1d6bc07e9129a8ba2272b08aa9a44baff6bad0708e5244dbc2224f44e1;
}