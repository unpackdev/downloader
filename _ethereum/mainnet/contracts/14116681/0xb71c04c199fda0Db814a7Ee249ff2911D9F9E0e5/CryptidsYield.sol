// SPDX-License-Identifier: MIT



pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

interface ICryptids {
    function balanceOf(address owner) external view returns(uint256);
}
interface IBounty {
    function mint(address _to, uint _amount) external;
}

contract BountyYield is Ownable {

    ICryptids public Cryptids;
    function setCryptidAddress(address _cryptid) external onlyOwner { Cryptids = ICryptids(_cryptid); }
    IBounty public Bounty;
    function setBountyAddress(address _bounty) external onlyOwner { Bounty = IBounty(_bounty); }

    uint256 public GEN_RATE;
    function setGenYield(uint256 _genYield) external onlyOwner { GEN_RATE = _genYield; }

    uint256 public START;
    function updateStartTime(uint256 _start) external onlyOwner { START = _start; }

    bool rewardPaused = false;
    function toggleReward() public onlyOwner { rewardPaused = !rewardPaused; }

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    constructor(address _cryptid, uint256 startTime) {
        Cryptids = ICryptids(_cryptid);
        START = startTime;
    }

    function updateReward(address from, address to) external {
        require(msg.sender == address(Cryptids));
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
    Bounty.mint(msg.sender, rewards[msg.sender] + getPendingReward(msg.sender));
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function getPendingReward(address user) internal view returns(uint256) {
        return Cryptids.balanceOf(user) * GEN_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) / 86400;
    }

}