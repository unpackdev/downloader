// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";

contract TribotStaking is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    IERC20MetadataUpgradeable public token;
    uint256 public totalStaked;
    uint256 public minDeposit;
    uint256 public timeStep;
    uint256 public percentDivider;
    uint256 public basePercent;
    uint256 public uniqueStakers;

    // Initialize the contract
    function initialize(IERC20MetadataUpgradeable _token) external initializer {
        __Ownable_init();

        token = _token;
        minDeposit = 100 * 10 ** token.decimals();
        timeStep = 14 days;
        percentDivider = 100_00;
        basePercent = 10;
    }

    struct User {
        uint256 amount;
        uint256 checkpoint;
        uint256 claimedReward;
        uint256 totalclaimed;
        uint256 reward;
        uint256 startTime;
        uint256 withdrawTime;
        bool isActive;
        bool isExists;
    }
    mapping(address => User) public users;

    event STAKE(address Staker, uint256 amount);
    event CLAIM(address Staker, uint256 amount);
    event WITHDRAW(address Staker, uint256 amount);

    function stake(uint256 _amount) public {
        User storage user = users[msg.sender];
        require(_amount >= minDeposit, "Amount less than min amount");
        if (!user.isExists) {
            user.isExists = true;
            uniqueStakers++;
            user.startTime = block.timestamp;
        } else {
            uint256 claimableReward = calculateReward(msg.sender);
            if (claimableReward > 0) {
                token.transfer(msg.sender, claimableReward);
            }
        }

        token.transferFrom(msg.sender, address(this), _amount);
        user.amount += _amount;
        user.claimedReward = 0;
        user.reward = user.amount.mul(basePercent).div(percentDivider);
        totalStaked += _amount;
        user.checkpoint = block.timestamp;
        user.withdrawTime = block.timestamp + timeStep;
        user.isActive = true;

        emit STAKE(msg.sender, _amount);
    }

    function claim() public {
        User storage user = users[msg.sender];
        require(user.isActive, "Already withdrawn");
        uint256 rewardAmount;
        rewardAmount = calculateReward(msg.sender);
        require(rewardAmount > 0, "Can't claim 0");
        token.transfer(msg.sender, rewardAmount);
        user.checkpoint = block.timestamp;
        user.claimedReward += rewardAmount;
        user.totalclaimed += rewardAmount;
        emit CLAIM(msg.sender, rewardAmount);
    }

    function restake() public {
        User storage user = users[msg.sender];
        uint256 claimableReward = calculateReward(msg.sender);
        require(claimableReward > 0, "Nothing to restake");
        user.claimedReward = 0;
        user.totalclaimed += claimableReward;
        user.amount += claimableReward;
        user.checkpoint = block.timestamp;
        user.reward = user.amount.mul(basePercent).div(percentDivider);
        user.withdrawTime = block.timestamp + timeStep;
        totalStaked += claimableReward;
    }

    function calculateReward(address _user) public view returns (uint256) {
        User storage user = users[_user];
        uint256 _reward;
        uint256 rewardDuration = block.timestamp.sub(user.checkpoint);
        _reward = user.amount.mul(rewardDuration).mul(basePercent).div(
            percentDivider.mul(timeStep)
        );
        if (_reward.add(user.claimedReward) > user.reward) {
            _reward = user.reward.sub(user.claimedReward);
        }
        return _reward;
    }

    function withdraw() public {
        User storage user = users[msg.sender];
        require(user.isActive, "user is not active!");
        require(block.timestamp > user.withdrawTime, "Wait for withdraw time!");
        token.transfer(msg.sender, user.amount);
        uint256 claimAbleReward = calculateReward(msg.sender);
        if (claimAbleReward > 0) {
            claim();
        }
        user.amount = 0;
        user.reward = 0;
        user.claimedReward = 0;
        user.totalclaimed = claimAbleReward;
        user.isActive = false;
    }

    function updateToken(IERC20MetadataUpgradeable _token) public onlyOwner {
        require(address(_token) != address(0), "token address cannot be 0");
        token = _token;
    }

    function updateTimeStep(uint256 _timeStep) public onlyOwner {
        timeStep = _timeStep;
    }

    function setBasePercent(uint256 _basePercent) public onlyOwner {
        basePercent = _basePercent;
    }

    function setPercentDivider(uint256 _percentDivider) public onlyOwner {
        percentDivider = _percentDivider;
    }
}
