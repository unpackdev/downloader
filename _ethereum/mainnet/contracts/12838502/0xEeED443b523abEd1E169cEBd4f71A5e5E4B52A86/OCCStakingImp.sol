// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./Math.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract OCCStakingImp is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public OCC;
    mapping(address => uint) public stakes;
    uint256 public totalStake;

    uint256[] public checkPoints; 
    uint256[] public rewardPerSecond; 
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored; // per 1 OCC, i.e. per 10**18 units

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint public unstakingFeeRatio;
    uint public newUnstakingFeeRatio;
    uint public unstakingFeeRatioTimelock;
    uint public constant unstakingFeeRatioTimelockPeriod = 600;
    uint public constant unstakingFeeDenominator = 10000;
    uint public constant OCCUnits = 1e18;

    bool public initialized = false;
    uint public startingCheckPoint;

    event CreateStake(address indexed caller, uint amount);
    event RemoveStake(address indexed caller, uint amount);
    event TransferStake(address indexed from, address indexed to, uint amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _owner) Ownable(_owner) {}
    
    /* function initialize(address _OCC, uint _unstakingFeeRatio, address _owner, uint emissionStart, uint firstCheckPoint, uint _rewardPerSecond) public {
        require(initialized == false, "OCCStakingImp: contract has already been initialized.");
        OCC = IERC20(_OCC);
        unstakingFeeRatio = _unstakingFeeRatio;
        newUnstakingFeeRatio = _unstakingFeeRatio;
        if (checkPoints.length == 0) {
            checkPoints.push(emissionStart);
            checkPoints.push(firstCheckPoint);
            rewardPerSecond.push(_rewardPerSecond);
        }
        owner = _owner;
        initialized = true;
    } */

    function createStake(uint stake) public nonReentrant updateReward(msg.sender) {
        OCC.safeTransferFrom(msg.sender, address(this), stake);
        stakes[msg.sender] = stakes[msg.sender].add(stake);
        totalStake = totalStake.add(stake);
        emit CreateStake(msg.sender, stake);
    }

    function createStakeFor(uint stake, address to) public nonReentrant updateReward(to) {
        OCC.safeTransferFrom(msg.sender, address(this), stake);
        stakes[to] = stakes[to].add(stake);
        totalStake = totalStake.add(stake);
        emit CreateStake(to, stake);
    }

    function getRewardThenStake() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            require(reward < OCC.balanceOf(address(this)).sub(totalStake), "OCCStaking: not enough tokens to pay out reward.");
            rewards[msg.sender] = 0;
            stakes[msg.sender] = stakes[msg.sender].add(reward);
            totalStake = totalStake.add(reward);
            emit CreateStake(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function removeStake(uint stake, uint maximumFee) public nonReentrant updateReward(msg.sender) {
        uint unstakingFee = stake.mul(unstakingFeeRatio).div(unstakingFeeDenominator);
        require(unstakingFee <= maximumFee, "OCCStaking: fee too high.");
        uint stakeWithoutFee = stake.sub(unstakingFee);
        require(stakes[msg.sender] >= stake, "OCCStaking: INSUFFICIENT_STAKE");
        stakes[msg.sender] = stakes[msg.sender].sub(stake);
        totalStake = totalStake.sub(stake);
        OCC.safeTransfer(msg.sender, stakeWithoutFee);
        emit RemoveStake(msg.sender, stake);
    }

    function transferStake(address _recipient, uint _amount) public {
        require(_amount <= stakes[msg.sender], "OCCStakingImp: not enough stake to transfer");
        _updateReward(msg.sender);
        _updateReward(_recipient);
        stakes[msg.sender] = stakes[msg.sender].sub(_amount);
        stakes[_recipient] = stakes[_recipient].add(_amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            require(reward <= OCC.balanceOf(address(this)).sub(totalStake), "OCCStaking: not enough tokens to pay out reward.");
            rewards[msg.sender] = 0;
            OCC.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function showPendingReward(address account) public view returns (uint256) {
        uint rewardPerTokenStoredActual;
        if (totalStake != 0) {
            (uint256 totalEmittedTokensSinceLastUpdate, ) = getTotalEmittedTokens(lastUpdateTime, block.timestamp, startingCheckPoint);
            rewardPerTokenStoredActual = rewardPerTokenStored.add(totalEmittedTokensSinceLastUpdate.mul(OCCUnits).div(totalStake));
        } else {
            rewardPerTokenStoredActual = rewardPerTokenStored;
        }
        return rewards[account].add((rewardPerTokenStoredActual.sub(userRewardPerTokenPaid[account])).mul(stakes[account]).div(OCCUnits));
    }

    function _updateReward(address account) internal {
        if (totalStake != 0) {
            (uint256 totalEmittedTokensSinceLastUpdate, uint256 newStartingCheckPoint) = getTotalEmittedTokens(lastUpdateTime, block.timestamp, startingCheckPoint);
            startingCheckPoint = newStartingCheckPoint;
            rewardPerTokenStored = rewardPerTokenStored.add(totalEmittedTokensSinceLastUpdate.mul(OCCUnits).div(totalStake));
        }
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            uint256 _rewardPerTokenStored = rewardPerTokenStored;
            rewards[account] = rewards[account].add((_rewardPerTokenStored.sub(userRewardPerTokenPaid[account])).mul(stakes[account]).div(OCCUnits));
            userRewardPerTokenPaid[account] = _rewardPerTokenStored;
        }
    }
    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    function getStake(address user) public view returns (uint) {
        return stakes[user];
    }

    function setNewUnstakingFeeRatio(uint _newUnstakingFeeRatio) public onlyOwner {
        require(_newUnstakingFeeRatio <= unstakingFeeDenominator, "OCCStaking: invalid unstaking fee.");
        newUnstakingFeeRatio = _newUnstakingFeeRatio;
        unstakingFeeRatioTimelock = block.timestamp.add(unstakingFeeRatioTimelockPeriod);
    }

    function changeUnstakingFeeRatio() public onlyOwner {
        require(block.timestamp >= unstakingFeeRatioTimelock, "OCCStaking: too early to change unstaking fee.");
        unstakingFeeRatio = newUnstakingFeeRatio;
    }

    function updateSchedule(uint checkPoint, uint _rewardPerSecond) public onlyOwner {
        uint lastCheckPoint = checkPoints[checkPoints.length.sub(1)];
        require(checkPoint > Math.max(lastCheckPoint, block.timestamp), "LM: new checkpoint has to be in the future");
        if (block.timestamp > lastCheckPoint) {
            checkPoints.push(block.timestamp);
            rewardPerSecond.push(0);
        }
        checkPoints.push(checkPoint);
        rewardPerSecond.push(_rewardPerSecond);
    }

    function getCheckPoints() public view returns (uint256[] memory) {
        return checkPoints;
    }

    function getRewardPerSecond() public view returns (uint256[] memory) {
        return rewardPerSecond;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, checkPoints[checkPoints.length.sub(1)]);
    }

    function getTotalEmittedTokens(uint256 _from, uint256 _to, uint256 _startingCheckPoint) public view returns (uint256, uint256) {
        require(_to >= _from, "LM: _to has to be greater than _from.");
        uint256 totalEmittedTokens = 0;
        uint256 workingTime = Math.max(_from, checkPoints[0]);
        if (_to <= workingTime) {
            return (0, _startingCheckPoint);
        }
        uint checkPointsLength = checkPoints.length;
        for (uint256 i = _startingCheckPoint + 1; i < checkPointsLength; ++i) {
            uint256 emissionTime = checkPoints[i];
            uint256 emissionRate = rewardPerSecond[i-1];
            if (_to < emissionTime) {
                totalEmittedTokens = totalEmittedTokens.add(_to.sub(workingTime).mul(emissionRate));
                return (totalEmittedTokens, i-1);
            } else if (workingTime < emissionTime) {
                totalEmittedTokens = totalEmittedTokens.add(emissionTime.sub(workingTime).mul(emissionRate));
                workingTime = emissionTime;
            }
        }
        return (totalEmittedTokens, checkPointsLength.sub(1));
    }

}