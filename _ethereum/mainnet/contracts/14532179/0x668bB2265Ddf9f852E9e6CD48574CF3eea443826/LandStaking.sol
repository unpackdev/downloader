// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./console.sol";

contract LandStaking is Ownable, ERC1155Holder, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant SECS_IN_DAY = 86400;
    uint256 public constant REWARD_DENOMINATOR = 1000000000000000000;
    bool public paused;

    IERC20 public xbmf;
    IERC1155 public land;
    mapping(address => mapping(uint256 => uint256)) stakedLandCount;
    mapping(uint256 => uint256) skullBoosts;
    mapping(uint256 => uint256) dailyYield;
    mapping(address => uint256) lastUpdate;
    mapping(address => uint256) rewards;
    uint256 taxRate;
    uint256 totalTaxes;

    mapping(address => bool) components;

    modifier onlyComponent() {
       if (!components[msg.sender]) revert();
        _;
    }

    constructor() {
        dailyYield[0] = 20 ether;
        dailyYield[1] = 40 ether;
        dailyYield[2] = 60 ether;
        dailyYield[3] = 100 ether;
        skullBoosts[4] = 15;
        skullBoosts[5] = 20;
        skullBoosts[6] = 25;
        skullBoosts[7] = 30;
    }

    // Admin

    // Add tokens which will be used to pay out rewards
    function addXBMF(uint256 amount) external onlyOwner {
        xbmf.transferFrom(msg.sender, address(this), amount);
    }

    // Withdraw tokens used to pay out rewards. Should normally be used only if change to new contract, or emergency to protect users.
    function withdrawXBMF(uint256 amount) external onlyOwner {
        xbmf.transfer(msg.sender, amount);
    }

    // Withdraw tokens used to pay out rewards. Should normally be used only if change to new contract, or emergency to protect users.
    function withdrawAllXBMF() external onlyOwner {
        uint256 bal = xbmf.balanceOf(address(this));
        xbmf.transfer(msg.sender, bal);
    }

    // Components - for interaction between game contracts

    function transferXBMFByComponent(uint256 amount, address _address, address recipient) external onlyComponent {
        _updateRewards(_address);
        require(rewards[_address] > amount, "Transfer amount exceeds rewards");
        xbmf.transfer(recipient, amount);
        rewards[_address] -= amount;
    }

    function transferTaxes(address _recipient) external onlyComponent {
        if (totalTaxes > 0) {
            totalTaxes = 0;
            xbmf.transfer(_recipient, totalTaxes);
        }
    }

    // Setters

    // 10 means 10%
    function setTaxRate(uint256 _taxRate) external onlyOwner {
        taxRate = _taxRate;
    }

    function addComponent(address component, bool value) external onlyOwner {
        components[component] = value;
    }

    function pause(bool value) external onlyOwner {
        paused = value;
    }

    function setXBMFAddress(address _address) external onlyOwner {
        xbmf = IERC20(_address);
    }

    function setLandAddress(address _address) external onlyOwner {
        land = IERC1155(_address);
    }

    function setDailyYield(uint256 landType, uint256 yieldPerDay)
        external
        onlyOwner
    {
        dailyYield[landType] = yieldPerDay;
    }

    //Getters
    function getStakedBalance(address _address, uint256 landType)
        public
        view
        returns (uint256)
    {
        return stakedLandCount[_address][landType];
    }

    function getAllStakedBalances(address _address) public view returns (uint256[8] memory) {
        return [
            stakedLandCount[_address][0],
            stakedLandCount[_address][1],
            stakedLandCount[_address][2],
            stakedLandCount[_address][3],
            stakedLandCount[_address][4],
            stakedLandCount[_address][5],
            stakedLandCount[_address][6],
            stakedLandCount[_address][7]
        ];
    }

    function getDailyYield(uint256 landType) public view returns (uint256) {
        return dailyYield[landType];
    }

    function getTotalTaxes() public view returns (uint256) {
        return totalTaxes;
    }

    function getTaxRate() public view returns (uint256) {
        return taxRate;
    }

    function isComponent(address _address) public view returns (bool) {
        return components[_address];
    }

    function viewRewards(address _address) public view returns (uint256) {
        uint256 lastTime = lastUpdate[_address];
        if (lastTime == 0) {
            return 0;
        }

        uint256 additionalRewards = _getRewardForLandType(0, _address)
            .add(_getRewardForLandType(1, _address))
            .add(_getRewardForLandType(2, _address))
            .add(_getRewardForLandType(3, _address))
            .mul(block.timestamp.sub(lastTime))
            .div(SECS_IN_DAY);  
        console.log("viewRewards _getRewardsForLandType 0", _getRewardForLandType(0, _address).div(REWARD_DENOMINATOR));    
        console.log("viewRewards previous rewards", rewards[_address].div(REWARD_DENOMINATOR));    
        console.log("viewRewards additional rewards", additionalRewards.div(REWARD_DENOMINATOR)); 
        uint256 booster = _getBoosterForSkulls(_address)
        .mul(block.timestamp.sub(lastTime))
            .div(SECS_IN_DAY);  
        additionalRewards = additionalRewards.add(booster);   
      
        uint256 result = rewards[_address].add(additionalRewards);
        console.log("viewRewards result", result.div(REWARD_DENOMINATOR));
        return result;
    }

    // Internal

    function _getRewardForLandType(uint256 landType, address _address)
        internal
        view
        returns (uint256)
    {
        return dailyYield[landType].mul(stakedLandCount[_address][landType]);
    }

    function _getBoosterForSkulls(address _address) internal view returns (uint256) {
        uint256 totalLandCount = stakedLandCount[_address][0]
        .add(stakedLandCount[_address][1])
        .add(stakedLandCount[_address][2])
        .add(stakedLandCount[_address][3]);
        console.log("All Land:", totalLandCount);

        uint256 booster = 0;
        for (uint8 i = 0; i < 4; i++){
            uint256 landEarnings = 0;
            if (totalLandCount > stakedLandCount[_address][i+4].mul(2)) {
                landEarnings = stakedLandCount[_address][i+4].mul(2).mul(dailyYield[i]);
            } else {
                landEarnings = totalLandCount.mul(dailyYield[i]);
            }
            booster += landEarnings.mul(skullBoosts[i+4]).mul(stakedLandCount[_address][i+4]).div(10).sub(landEarnings);
        }
       
        console.log("ZZZ commonBooster:", booster.div(REWARD_DENOMINATOR));
        return booster;
    }

    function _updateRewards(address _address) internal {
        uint256 lastTime = lastUpdate[_address];
        if (lastTime == 0) {
            lastUpdate[_address] = block.timestamp;
            console.log("XXX _updateRewards first time. return");
            return;
        }
        console.log("---------");
        console.log("block.timestamp.sub(lastTime)", block.timestamp.sub(lastTime));

        uint256 additionalRewards = _getRewardForLandType(0, _address)
            .add(_getRewardForLandType(1, _address))
            .add(_getRewardForLandType(2, _address))
            .add(_getRewardForLandType(3, _address))
            .mul(block.timestamp.sub(lastTime))
            .div(SECS_IN_DAY);
        console.log("additionalRewards before multiplier", additionalRewards.div(REWARD_DENOMINATOR));
         uint256 booster = _getBoosterForSkulls(_address)
        .mul(block.timestamp.sub(lastTime))
            .div(SECS_IN_DAY);  
        additionalRewards = additionalRewards.add(booster); 
        
        console.log("additionalRewards after multiplier", additionalRewards.div(REWARD_DENOMINATOR));
        
        rewards[_address] = rewards[_address].add(additionalRewards);
        lastUpdate[_address] = block.timestamp;
    }

    // User Actions

    function claimRewards() external nonReentrant {
        console.log("LLL claimRewards", taxRate);
        require(!paused, "Contract is paused");
        _updateRewards(msg.sender);
        uint256 bal = rewards[msg.sender];
        if (bal > 0) {
            rewards[msg.sender] = 0;
            if (taxRate > 0) {
                console.log("LLL taxRate", taxRate);
                uint256 tax = bal.mul(taxRate).div(100);
                console.log("LLL tax amount", tax.div(REWARD_DENOMINATOR));
                bal = bal.sub(tax);
                console.log("Bal to pay out", bal.div(REWARD_DENOMINATOR));
                totalTaxes += tax;
            }
            xbmf.transfer(msg.sender, bal);
        }
    }

    function stake(uint256 landType, uint256 num) external {
        require(!paused, "Contract is paused");
        require(land.balanceOf(msg.sender, landType) > 0, "No land to stake");
        require(
            land.balanceOf(msg.sender, landType) >= num,
            "You land count need to match or exceed your intended stake count"
        );
        // transfer the land to the contract
        land.safeTransferFrom(msg.sender, address(this), landType, num, "");
        stakedLandCount[msg.sender][landType] += num;
        _updateRewards(msg.sender);
    }

    function unstake(uint256 landType, uint256 num) external {
        require(!paused, "Contract is paused");
        require(
            stakedLandCount[msg.sender][landType] > 0,
            "You don't have any land of that type staked"
        );
        require(
            stakedLandCount[msg.sender][landType] >= num,
            "You don't have enough staked land to unstake that amount"
        );
        land.safeTransferFrom(address(this), msg.sender, landType, num, "");
        stakedLandCount[msg.sender][landType] -= num;
        _updateRewards(msg.sender);
    }
}
