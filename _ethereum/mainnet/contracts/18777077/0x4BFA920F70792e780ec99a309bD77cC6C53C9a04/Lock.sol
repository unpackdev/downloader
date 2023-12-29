// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Ownable.sol";

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract StakingContract is Ownable {
    IERC20 public token;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        uint256 rewardPercentage;
        bool active;
        uint256 claimedAmount;
    }

    uint256 public rewardPercentage30Days = 10;
    uint256 public rewardPercentage60Days = 25;
    uint256 public rewardPercentage90Days = 45;

    uint public paneltyPercentage = 5;

    mapping(address => Stake[]) public stakes;

    event Staked(address indexed user, uint256 amount, uint256 duration);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdrawn(address indexed user, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function stake(uint256 _amount, uint256 _duration) external {
        require(
            _duration == 30 || _duration == 60 || _duration == 90,
            "Invalid duration"
        );

        uint256 rewardPercentage = 0;
        if (_duration == 30) {
            rewardPercentage = rewardPercentage30Days;
        } else if (_duration == 60) {
            rewardPercentage = rewardPercentage60Days;
        } else if (_duration == 90) {
            rewardPercentage = rewardPercentage90Days;
        }

        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        stakes[msg.sender].push(
            Stake({
                amount: _amount,
                startTime: block.timestamp,
                duration: _duration * 1 days,
                rewardPercentage: rewardPercentage,
                active: true,
                claimedAmount: 0
            })
        );

        emit Staked(msg.sender, _amount, _duration);
    }

    function calculateReward(
        address _user,
        uint256 _stakeIndex
    ) public view returns (uint256) {
        Stake memory userStake = stakes[_user][_stakeIndex];
        uint256 timeElapsed = block.timestamp - userStake.startTime;
        uint256 duration = userStake.duration;

        if (!userStake.active) return 0;

        if (timeElapsed >= duration && userStake.active) {
            return (userStake.amount * userStake.rewardPercentage) / 100;
        } else {
            return
                (userStake.amount * userStake.rewardPercentage * timeElapsed) /
                (100 * userStake.duration);
        }
    }

    // Function for regular withdrawal (allowed after lock period)
    function withdraw(uint256 _stakeIndex) external {
        require(_stakeIndex < stakes[msg.sender].length, "Invalid stake index");

        Stake storage userStake = stakes[msg.sender][_stakeIndex];
        uint256 reward = calculateReward(msg.sender, _stakeIndex);
        uint256 timeElapsed = block.timestamp - userStake.startTime;

        require(reward > 0, "No rewards to claim yet");
        require(timeElapsed >= userStake.duration, "Lock period not ended");

        uint256 withdrawAmount = userStake.amount + reward;

        require(token.transfer(msg.sender, withdrawAmount), "Transfer failed");

        userStake.active = false;
        userStake.claimedAmount = reward;

        emit Withdrawn(msg.sender, withdrawAmount);
    }

    // Function for emergency withdrawal (allowed before lock period ends)
    function emergencyWithdraw(uint256 _stakeIndex) external {
        require(_stakeIndex < stakes[msg.sender].length, "Invalid stake index");

        Stake storage userStake = stakes[msg.sender][_stakeIndex];
        uint256 reward = calculateReward(msg.sender, _stakeIndex);
        uint256 timeElapsed = block.timestamp - userStake.startTime;

        require(timeElapsed < userStake.duration, "Lock period ended");

        uint256 penalty = ((userStake.amount + reward) * paneltyPercentage) /
            100;
        uint256 withdrawAmount = userStake.amount + reward - penalty;

        require(token.transfer(msg.sender, withdrawAmount), "Transfer failed");

        userStake.active = false;
        userStake.claimedAmount = reward;

        emit EmergencyWithdrawn(msg.sender, withdrawAmount);
    }

    function getStakesCount(address _user) external view returns (uint256) {
        return stakes[_user].length;
    }

    function getStakeDetails(
        address _user,
        uint256 _index
    )
        external
        view
        returns (
            uint256 amount,
            uint256 startTime,
            uint256 duration,
            uint256 rewardPercentage,
            bool active
        )
    {
        Stake memory userStake = stakes[_user][_index];

        return (
            userStake.amount,
            userStake.startTime,
            userStake.duration,
            userStake.rewardPercentage,
            userStake.active
        );
    }

    function ownerWithdrawTokens(uint256 _amount) external onlyOwner {
        require(token.transfer(msg.sender, _amount), "Transfer failed");
    }

    function withdrawBep20Tokens(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    // Function for the contract owner to update reward percentages
    function updateRewardPercentages(
        uint256 _rewardPercentage30Days,
        uint256 _rewardPercentage60Days,
        uint256 _rewardPercentage90Days
    ) external onlyOwner {
        rewardPercentage30Days = _rewardPercentage30Days;
        rewardPercentage60Days = _rewardPercentage60Days;
        rewardPercentage90Days = _rewardPercentage90Days;
    }

    function changePaneltyAmount(uint _panelty) external onlyOwner {
        paneltyPercentage = _panelty;
    }
}
