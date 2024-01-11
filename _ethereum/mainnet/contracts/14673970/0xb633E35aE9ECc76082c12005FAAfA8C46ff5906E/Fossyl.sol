//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

interface iDinodoods {
    function balanceOf(address owner) external view returns(uint256);
}

contract Fossyl is ERC20, Ownable {

    iDinodoods public Dinodoods;

    uint256 public BASE_RATE = 3 ether;
    uint256 public START;
    bool public rewardPaused = false;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;
    mapping(address => bool) public allowedAddresses;

    constructor() ERC20("Fossyl", "FOSSYL") {
        START = block.timestamp;
    }

    function updateReward(address from, address to) external {
        require(msg.sender == address(Dinodoods));
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

    function claimFossyl(address _address, uint256 _amount) external {
        require(!rewardPaused,                "Claiming reward has been paused"); 
        require(allowedAddresses[msg.sender], "Address does not have permission to distrubute tokens");
        _mint(_address, _amount);
    }

    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(Dinodoods), "Address does not have permission to burn");
        _burn(user, amount);
    }

    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function getPendingReward(address user) internal view returns(uint256) {
        return Dinodoods.balanceOf(user) * BASE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) / 86400;
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }

    function setDinoDoods(address DinodoodsAddress) external onlyOwner {
      Dinodoods = iDinodoods(DinodoodsAddress);
    }

    function setBaseRate(uint256 baseRate) external onlyOwner {
        BASE_RATE = baseRate;
    }
}