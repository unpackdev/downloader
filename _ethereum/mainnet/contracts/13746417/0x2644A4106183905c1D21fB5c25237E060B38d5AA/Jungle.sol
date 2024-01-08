// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

interface iTigerCubClub {
    function balanceOfOwner(address owner) external view returns(uint256, uint256);
}

contract Jungle is ERC20, Ownable {

    iTigerCubClub public TigerCubClub;

    uint256 constant public BASE_RATE = 5 ether;
    uint256 public START;
    bool public rewardPaused = false;

    uint256 public BONUS_TIMESTAMP; // we will set this when sold out

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    mapping(address => bool) public allowedAddresses;

    constructor(address tigerCubAddress, uint256 _start) ERC20("Jungle", "JUNGLE") {
        TigerCubClub = iTigerCubClub(tigerCubAddress);
        START = _start < block.timestamp ? block.timestamp : _start;
    }

    function updateReward(address from, address to) external {
        require(msg.sender == address(TigerCubClub));
        if(from != address(0)){
            rewards[from] += getPendingReward(from);
            lastUpdate[from] = block.timestamp;
        }
        if(to != address(0)){
            rewards[to] += getPendingReward(to);
            lastUpdate[to] = block.timestamp;
        }
    }

    function claimReward() external {
        require(!rewardPaused, "Claiming reward has been paused"); 
        _mint(msg.sender, rewards[msg.sender] + getPendingReward(msg.sender));
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

    // !ooh
    function claimLaboratoryExperimentRewards(address _address, uint256 _amount) external {
        require(!rewardPaused,                "Claiming reward has been paused"); 
        require(allowedAddresses[msg.sender], "Address does not have permission to distrubute tokens");
        _mint(_address, _amount);
    }

    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(TigerCubClub), "Address does not have permission to burn");
        _burn(user, amount);
    }

    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function getPendingReward(address user) internal view returns(uint256) {
        if(START > block.timestamp) return 0;

        uint256 bonus = 0;

        (uint256 presaleBalance, uint256 genesisBalance) = TigerCubClub.balanceOfOwner(user);
        // presale bonus
        if(BONUS_TIMESTAMP > 0) {
            if(lastUpdate[user] < BONUS_TIMESTAMP && BONUS_TIMESTAMP < block.timestamp) {
                bonus += presaleBalance * 50 ether; // presale bonus
                bonus += genesisBalance * 50 ether; // mint bonus
            }

            // all holder bonus
            uint256 holderBonusTimestamp = BONUS_TIMESTAMP + 30 days;
            if(lastUpdate[user] < holderBonusTimestamp && block.timestamp > holderBonusTimestamp) bonus += 50 ether;
        }

        return bonus + (genesisBalance * BASE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) / 86400);
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function setRewardPaused(bool _status) public onlyOwner {
        rewardPaused = _status;
    }

    // @dev only when sold out
    function setBonusTimestamp(uint256 _timestamp) public onlyOwner {
        require(BONUS_TIMESTAMP == 0, "Already set"); 
        BONUS_TIMESTAMP = _timestamp;
    }

    // @dev emergeny call
    function setStartTimestamp(uint256 _timestamp) public onlyOwner {
        require(START > block.timestamp, "Invalid time"); 
        START = _timestamp;
    }
}