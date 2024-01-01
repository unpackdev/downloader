// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
Always Bullish 🐂

https://wallstreetbulls.xyz/
https://twitter.com/WSBullsOfficial
https://t.me/WallStreetBullsPortal

*/

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract TokenStaker is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    IERC20 public token;

    uint256 public totalStaked;
    uint256 public maximumStakeLimit;
    uint256 public rewardsRemaining;
    uint256 public rewardsTotal;
    uint256 public minimumStakePerWallet;
    uint256 public maximumStakePerWallet;
    
    uint256 public APR = 5_000; // 50%
    
    uint256 public lockDuration = 7 * 24 * 60 * 60; // 1 Week

    mapping(address => Staker) private stakersMapping;
    address[] private stakerAddresses;

    struct Staker {
        uint256 amount;
        uint256 stakeTimestamp;
        uint256 lastClaimTimestamp;
        uint256 amountSavedToClaim;
        uint256 unlockTimestamp;
    }
    
    event StakeSuccessful(address user, uint256 amount, uint256 total);
    event StakeRewardsSuccessful(address user, uint256 amount, uint256 total);
    event UnstakeSuccessful(address user, uint256 amount, uint256 remaining);
    event ClaimRewardSuccessful(address user, uint256 amount);

    constructor() { }

    function stake(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Must stake more than 0 tokens");
        require(totalStaked + _amount <= maximumStakeLimit || maximumStakeLimit == 0, "Staking limit reached");
        require(stakersMapping[msg.sender].amount + _amount >= minimumStakePerWallet || minimumStakePerWallet == 0, "Must stake a minimum amount");
        require(stakersMapping[msg.sender].amount + _amount <= maximumStakePerWallet || maximumStakePerWallet == 0, "maximumStakePerWallet reached");

        token.safeTransferFrom(msg.sender, address(this), _amount);
        
        uint256 _previousAmountForThisStaker = stakersMapping[msg.sender].amount;
        if (_previousAmountForThisStaker > 0 && stakersMapping[msg.sender].stakeTimestamp > 0) {
            stakersMapping[msg.sender].amountSavedToClaim += getRewardAmountToClaim(msg.sender);
            stakersMapping[msg.sender].lastClaimTimestamp = block.timestamp;
            stakersMapping[msg.sender].unlockTimestamp = block.timestamp + lockDuration;

            stakersMapping[msg.sender].amount += _amount;
            stakersMapping[msg.sender].stakeTimestamp = block.timestamp;
        } else {
            stakersMapping[msg.sender] = Staker(_amount, block.timestamp, block.timestamp, 0, block.timestamp + lockDuration);
            stakerAddresses.push(msg.sender);
        }

        totalStaked += _amount;
        
        emit StakeSuccessful(msg.sender, _amount, stakersMapping[msg.sender].amount);
    }
    
    function claimReward() external nonReentrant {
        _claimReward();
    }

    function _claimReward() internal {
        uint256 _reward = getRewardAmountToClaim(msg.sender) + stakersMapping[msg.sender].amountSavedToClaim;
        if (_reward > 0) {
            if (token.transfer(msg.sender, _reward) == true) {
                stakersMapping[msg.sender].lastClaimTimestamp = block.timestamp;
                stakersMapping[msg.sender].amountSavedToClaim = 0;
                rewardsRemaining -= _reward;
                
                emit ClaimRewardSuccessful(msg.sender, _reward);
            }
            else revert();
        }
    }

    function unstake(uint256 _amount) public nonReentrant {
        require(_amount <= stakersMapping[msg.sender].amount && _amount > 0, "Not enough tokens staked.");
        require(block.timestamp > stakersMapping[msg.sender].unlockTimestamp, "Lock duration not through.");
        _claimReward();

        if (token.transfer(msg.sender, _amount) == true) {
            if (_amount < stakersMapping[msg.sender].amount) {
                stakersMapping[msg.sender].amountSavedToClaim += getRewardAmountToClaim(msg.sender);
                stakersMapping[msg.sender].lastClaimTimestamp = block.timestamp;
                stakersMapping[msg.sender].stakeTimestamp = block.timestamp;
            }
            
            stakersMapping[msg.sender].amount -= _amount;
            totalStaked -= _amount;

            emit UnstakeSuccessful(msg.sender, _amount, stakersMapping[msg.sender].amount);
        }
        else revert();
    }

    function stakeRewards() public nonReentrant {
        uint256 _reward = getRewardAmountToClaim(msg.sender);
        require(_reward > 0, "No reward available to restake");
        require(stakersMapping[msg.sender].amount + _reward <= maximumStakePerWallet || maximumStakePerWallet == 0, "maximumStakePerWallet reached");
        stakersMapping[msg.sender].amount += _reward;
        stakersMapping[msg.sender].stakeTimestamp = block.timestamp;
        stakersMapping[msg.sender].lastClaimTimestamp = block.timestamp;
        stakersMapping[msg.sender].unlockTimestamp = block.timestamp + lockDuration;

        totalStaked += _reward;

        emit StakeRewardsSuccessful(msg.sender, _reward, stakersMapping[msg.sender].amount);
    }

    // GETTERS

    function getRewardAmountToClaim(address _user) public view returns (uint256) {
        uint256 timePastLastClaim = block.timestamp - stakersMapping[_user].lastClaimTimestamp;
        uint256 amount = stakersMapping[_user].amount;
        uint256 year = 365 * 24 * 60 * 60;
        // APR: 5_000 // 50%
        // year reward divided by the actual time staked
        uint256 timelapseReward = (amount * APR * timePastLastClaim) / (year * 10_000);
        return timelapseReward;
    }

    function getStakerAmount(address _user) public view returns (uint256) {
        return stakersMapping[_user].amount;
    }
    function getStakerStakeTimestamp(address _user) public view returns (uint256) {
        return stakersMapping[_user].stakeTimestamp;
    }
    function getStakerLastClaimTimestamp(address _user) public view returns (uint256) {
        return stakersMapping[_user].lastClaimTimestamp;
    }
    function getStakerAmountSavedToClaim(address _user) public view returns (uint256) {
        return stakersMapping[_user].amountSavedToClaim;
    }
    function getStakerUnlockTimestamp(address _user) public view returns (uint256) {
        return stakersMapping[_user].unlockTimestamp;
    }

    function getStakers() external view returns (address[] memory) {
        return stakerAddresses;
    }

    // SETTERS

    function setMaximumStakeLimit(uint256 _maximumStakeLimit) public onlyOwner {
        maximumStakeLimit = _maximumStakeLimit;
    }

    function setRewardsTotal(uint256 _rewardsTotal) public onlyOwner {
        rewardsTotal = _rewardsTotal;
        rewardsRemaining = _rewardsTotal;
    }
    
    function setLockDuration(uint256 _lockDuration) public onlyOwner {
        lockDuration = _lockDuration;
    }
    
    function setAPR(uint256 _APR) public onlyOwner {
        APR = _APR;
    }

    function setMaximumStakePerWallet(uint256 _maximumStakePerWallet) public onlyOwner {
        maximumStakePerWallet = _maximumStakePerWallet;
    }

    function setMinimumStakePerWallet(uint256 _minimumStakePerWallet) public onlyOwner {
        minimumStakePerWallet = _minimumStakePerWallet;
    }

    // OWNER FUNCTIONS

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        token = IERC20(_tokenAddress);
    }
    
    function withdrawEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function withdrawToken() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}
