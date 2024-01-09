// SPDX-License-Identifier: MIT
// A Pixel Piracy Project - BOOTY IS A UTILITY TOKEN FOR THE PIXEL PIRACY ECOSYSTEM.
// $BOOTY is NOT an investment and has NO economic value.

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface IPirates {
    function balanceOf(address account) external view returns(uint256);
    function captainBalance(address owner) external view returns(uint256);
    function firstmateBalance(address owner) external view returns(uint256);
}

contract Booty is ERC20, Ownable {
    using SafeMath for uint256;

    IPirates public Pirates;
    address public Chests;

    uint256 constant public BASE_RATE = 10 ether;
    uint256 public START;
    bool rewardPaused = false;
    bool transferAllowed = false;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    mapping(address => bool) public allowedAddresses;

    constructor() ERC20("Booty", "BOOTY") {
        START = block.timestamp;
    }

    function setPirates(address pirateAddress) public onlyOwner {
        Pirates = IPirates(pirateAddress);
    }
    
    function setChests(address chestAddress) public onlyOwner {
        Chests = chestAddress;
    }

    function updateReward(address from, address to) external {
        require(msg.sender == address(Pirates));
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

    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(Pirates) || msg.sender == address(Chests), "Address does not have permission to burn");
        _burn(user, amount);
    }
    
    function mint(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(Pirates) || msg.sender == address(Chests), "Address does not have permission to mint");
        _mint(user, amount);
    }

    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function getPendingReward(address user) internal view returns(uint256) {
        uint256 captainBalance = Pirates.captainBalance(user);
        uint256 firstmateBalance = Pirates.firstmateBalance(user);
        uint256 crewBalance = Pirates.balanceOf(user) - captainBalance - firstmateBalance;
        uint256 claimTime = block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START);
        uint256 totalReward = crewBalance * BASE_RATE * claimTime / 86400;
        //1.25x for firstmate x5/4
        totalReward += firstmateBalance * BASE_RATE * 5 * claimTime / 345600;
        //1.5x for captain x3/2
        totalReward += captainBalance * BASE_RATE * 3 * claimTime / 172800;
        return totalReward;
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }
    
    function toggleTransfers() public onlyOwner {
        transferAllowed = !transferAllowed;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(transferAllowed, "Transfers of $BOOTY not allowed");
        return super.transferFrom(sender, recipient, amount);
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(transferAllowed, "Transfers of $BOOTY not allowed");
        return super.transfer(recipient, amount);
    }
}