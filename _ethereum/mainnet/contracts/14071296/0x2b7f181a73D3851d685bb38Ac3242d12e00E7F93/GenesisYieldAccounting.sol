// SPDX-License-Identifier: MIT



pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

interface IGenKatabolicz {
    function balanceOf(address owner) external view returns(uint256);
}
interface IToro {
    function mint(address _to, uint _amount) external;
}

contract ToroYieldGen is Ownable {

    IGenKatabolicz public GenKatabolicz;
    function setGenesisAddress(address _genAddress) external onlyOwner { GenKatabolicz = IGenKatabolicz(_genAddress); }
    IToro public Toro;
    function setToroAddress(address _toro) external onlyOwner { Toro = IToro(_toro); }

    uint256 public GEN_RATE;
    function setGenYield(uint256 _genYield) external onlyOwner { GEN_RATE = _genYield; }

    uint256 public START;
    function updateStartTime(uint256 _start) external onlyOwner { START = _start; }

    bool rewardPaused = false;
    function toggleReward() public onlyOwner { rewardPaused = !rewardPaused; }

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    constructor(address kataboliczGenesisAddress, uint256 startTime) {
        GenKatabolicz = IGenKatabolicz(kataboliczGenesisAddress);
        START = startTime;
    }

    function updateReward(address from, address to) external {
        require(msg.sender == address(GenKatabolicz));
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
    Toro.mint(msg.sender, rewards[msg.sender] + getPendingReward(msg.sender));
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function getPendingReward(address user) internal view returns(uint256) {
        return GenKatabolicz.balanceOf(user) * GEN_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) / 86400;
    }

}