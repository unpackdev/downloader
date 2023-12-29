// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./console.sol";

/*
Things to Improve:
- Find a way to fetch the rewards from unstaking simpler
*/

contract ArzStaking is Ownable, IERC721Receiver {
    ERC721A public nft;

    uint256 public stakedTotal;
    uint256 public rewardsPerDuration = 100;
    uint public durationUnit = 1 minutes;
    uint256 public downtime = 5 minutes;
    uint256 public commissionPer = 10;
    uint256 public mustTime = 5 minutes;

    struct Staker {
        uint256[] tokenIds; 
        mapping(uint256 => uint256) tokenStakingCoolDown;
        uint256 reward; 
        uint256 rewardClaimed;
    }
    
    //Constructor
    constructor(address _tokenAddress) {
        nft = ERC721A(_tokenAddress);
    }

    mapping(address => Staker) stakers;
    mapping(uint256 => address) tokenOwner;
    mapping(uint256 => uint256) unstakedTime;
    bool initialized = false;

    event Staked(address owner, uint256 amount);
    event Unstaked(address owner, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);


    ////////////////////////////
    // Setters and Accessors //
    ///////////////////////////
    function setDowntime(uint256 _downtime_in_hours) public {
        downtime = _downtime_in_hours * 1 hours;
    }

    function setMustTime(uint256 _mustTime_in_hours) public {
        mustTime = _mustTime_in_hours * 1 hours;
    }

    function setCommissionPercentage(uint256 _percentage) public {
        commissionPer = _percentage;
    }

    function setRewardPerDuration(uint256 _rewardsPerDuration) public {
        rewardsPerDuration = _rewardsPerDuration;
    }

    function setDurationUnit(uint256 _durationUnit_days) public {
        durationUnit = _durationUnit_days * 1 days;
    }

    function initStaking(bool _initialized) public onlyOwner {
        initialized = _initialized;
    }

    function getTokensStaked(address _user) public view returns (uint256[] memory){
        return stakers[_user].tokenIds; 
    }

    function getCurrentBalance(address _user) public view onlyOwner returns (uint256) {
        return stakers[_user].reward;
    }

    function getRewardsReleased(address _user) public view returns (uint256) {
        return stakers[_user].rewardClaimed; 
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override pure returns (bytes4) {
        return ERC721A__IERC721Receiver.onERC721Received.selector;
    }


    //////////////
    // Staking //
    /////////////
    function stake(uint256 tokenId) public {
        require(
            initialized,
            "Staking not allowed yet"
        );

        _stake(msg.sender, tokenId);
    }

    function stakeBatch(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i]);
        }
    }

    function _stake(address _user, uint256 _tokenId) internal {
        require(initialized, "Staking not allowed yet");
        require(
            nft.ownerOf(_tokenId) == _user,
            "User must be the owner of the token"
        );
        require(stakingRightCheck(_tokenId), "Unable to stake the token again before downtime");

        Staker storage staker = stakers[_user];
        staker.tokenIds.push(_tokenId);
        staker.tokenStakingCoolDown[_tokenId] = block.timestamp;
        tokenOwner[_tokenId] = _user;

        nft.approve(address(this), _tokenId);
        nft.safeTransferFrom(_user, address(this), _tokenId);

        emit Staked(_user, _tokenId);
        stakedTotal++;
    }


    ////////////////
    // Unstaking //
    ///////////////
    function unstake(uint256 _tokenId, uint256 ranking) public {
        calculateReward(msg.sender, _tokenId, ranking);
        _unstake(msg.sender, _tokenId);
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            tokenOwner[_tokenId] == _user,
            "User must be the owner of the staked nft"
        );

        Staker storage staker = stakers[_user];

        bool changed = false; 

        for (uint256 i = 0; i < staker.tokenIds.length; i++) {
            if (staker.tokenIds[i] == _tokenId) {
                staker.tokenIds[i] = staker.tokenIds[staker.tokenIds.length - 1];
                staker.tokenIds.pop();
                changed = true;
            }
        }

        require(changed, "Nft not staked");

        staker.tokenStakingCoolDown[_tokenId] = 0;
        delete tokenOwner[_tokenId];
        unstakedTime[_tokenId] = block.timestamp;

        nft.safeTransferFrom(address(this), _user, _tokenId);

        emit Unstaked(_user, _tokenId);
        stakedTotal--;
    }


    //////////////
    // Rewards //
    /////////////
    function calculateReward(address _user, uint256 _tokenId, uint256 ranking) internal {
        Staker storage staker = stakers[_user];
        uint256 timeConstant =  (block.timestamp - staker.tokenStakingCoolDown[_tokenId]) / durationUnit;

        require(timeConstant > 0, "No rewards yet");

        staker.reward += (timeConstant * rewardsPerDuration * ranking); 

        if ((block.timestamp - staker.tokenStakingCoolDown[_tokenId]) < mustTime) {
            staker.reward = (staker.reward * (100 - commissionPer)) / 100;
        }
    }

    function resetReward(address _user) public onlyOwner {
        uint256 rewardAmount = stakers[_user].reward;
        stakers[_user].rewardClaimed += rewardAmount;
        stakers[_user].reward = 0;

        emit RewardPaid(_user, rewardAmount);
    }

    function stakingRightCheck(uint256 _tokenId) public view returns (bool) {
        if (unstakedTime[_tokenId] != 0 &&
            block.timestamp - unstakedTime[_tokenId] < downtime) {
                return false;
        }
        return true;
    }
}
