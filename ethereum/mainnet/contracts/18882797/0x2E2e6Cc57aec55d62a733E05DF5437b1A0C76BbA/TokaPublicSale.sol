// SPDX-License-Identifier: MIT

pragma solidity =0.8.21;

import "./OwnableUpgradeable.sol";
import "./ITokaPublicSale.sol";

contract TokaPublicSale is OwnableUpgradeable {

    ITokaPublicSale public constant ROUND1 = ITokaPublicSale(0xA4c998C1CcDc35d046fEB0B6D2D98c4765360dC9);
    bytes32 public constant desiredKey = 0xe45565e026bfe5a143ba0e1f9ebb0f02bf84a41569210b2d276e204ab4731d93;

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
        require(totalReceived <= 348 ether, "over subscribe");
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
        uint256 amount = 348 ether;
        payable(to).transfer(amount);
    }

    // user round2 donation plus round1 rollover
    function userDonation(address user) public view returns(uint256){
        return ROUND1.userRollover(user) + userAmount[user];
    }
    function totalDonation() public view returns(uint256){
        return ROUND1.totalRollover() + totalReceived;
    }

    mapping (address => bool) public hasRefund;
    event Refund(address indexed user, uint256 amount);
    
    function refund() external{
        require(block.timestamp > endTime && endTime != 0, "Sale not end");
        require(!hasRefund[msg.sender], "already refund");
        require(!hasRollover[msg.sender], "already rollover");
        
        hasRefund[msg.sender] = true;

        uint256 amount = userDonation(msg.sender);
        require(amount > 0, "no fund available");

        // Total rollover amount in Round1 will be transferred to Round2, to ensure there is enough balance
        require(amount <= address(this).balance, "less than quota");

        userAmount[msg.sender] = 0;

        // If the money come from round1, these numbers will go negative, but no real side effect
        totalReceived -= amount;

        payable(msg.sender).transfer(amount);
        emit Refund(msg.sender, amount);
    }

    // rollover to next round
    uint256 public totalRollover;

    mapping(address => uint256) public userRollover;
    mapping(address => bool) public hasRollover;

    event Rollover(address user, uint256 amount);

    function rollOver(string memory key) external{
        // only tx from front end when round2 starts will proceed
        require(keccak256(abi.encodePacked(key)) == desiredKey, "wrong key");
        require(!hasRefund[msg.sender], "already refund");
        require(!hasRollover[msg.sender], "already rollover");

        hasRollover[msg.sender] = true;

        uint amount = userDonation(msg.sender);

        // deduct round2 info
        userAmount[msg.sender] = 0;
        totalReceived -= amount;

        // roll to next round, record the state
        userRollover[msg.sender] += amount;
        totalRollover += amount;

        emit Rollover(msg.sender, amount);
    }
}