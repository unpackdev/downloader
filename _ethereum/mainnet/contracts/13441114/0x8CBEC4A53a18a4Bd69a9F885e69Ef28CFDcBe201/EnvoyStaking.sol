// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./IERC20.sol";
import "./Ownable.sol";


contract EnvoyStaking is Ownable {
    event NewStake(address indexed user, uint256 totalStaked, uint256 totalDays, bool isEmbargo);
    event StakeFinished(address indexed user, uint256 totalRewards);
    event LockingIncreased(address indexed user, uint256 total);
    event LockingReleased(address indexed user, uint256 total);
    IERC20 token;
    uint256 dailyBonusRate = 10003271876792519; //1,0003271876792519
    
    uint256 public totalStakes;
    uint256 public totalActiveStakes;
    uint256 public totalStaked;
    uint256 public totalStakeClaimed;
    uint256 public totalRewardsClaimed;
    
    struct Stake {
        bool exists;
        uint256 createdOn;
        uint256 initialAmount;
        uint256 totalDays;
        bool claimed;
        bool isEmbargo;
    }
    
    mapping(address => Stake) stakes;
    mapping(address => uint256) public lockings;

    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function increaseLocking(address _beneficiary, uint256 _total) public onlyOwner {
        require(IERC20(token).transferFrom(msg.sender, address(this), _total), "Couldn't take the tokens");
        
        lockings[_beneficiary] += _total;
        
        emit LockingIncreased(_beneficiary, _total);
    }
    
    function releaseFromLocking(address _beneficiary, uint256 _total) public onlyOwner {
        require(lockings[_beneficiary] >= _total, "Not enough locked tokens");
        
        lockings[_beneficiary] -= _total;

        require(IERC20(token).transfer(_beneficiary, _total), "Couldn't send the tokens");
        
        emit LockingReleased(_beneficiary, _total);
    }

    function createEmbargo(address _account, uint256 _totalStake, uint256 _totalDays) public onlyOwner {
        _addStake(_account, _totalStake, _totalDays, true);
    }
    
    function createStake(uint256 _totalStake, uint256 _totalDays) public {
        _addStake(msg.sender, _totalStake, _totalDays, false);
    }
    
    function _addStake(address _beneficiary, uint256 _totalStake, uint256 _totalDays, bool _isEmbargo) internal {
        require(!stakes[_beneficiary].exists, "Stake already created");
        require(_totalDays > 29, "The minimum is 30 days");

        require(IERC20(token).transferFrom(msg.sender, address(this), _totalStake), "Couldn't take the tokens");
        
        Stake memory stake = Stake({exists:true,
                                    createdOn: block.timestamp, 
                                    initialAmount:_totalStake, 
                                    totalDays:_totalDays, 
                                    claimed:false,
                                    isEmbargo:_isEmbargo
        });
        
        stakes[_beneficiary] = stake;
                                    
        totalActiveStakes++;
        totalStakes++;
        totalStaked += _totalStake;
        
        emit NewStake(_beneficiary, _totalStake, _totalDays, _isEmbargo);
    }
    
    function finishStake() public {
        require(!stakes[msg.sender].isEmbargo, "This is an embargo");

        _finishStake(msg.sender);
    }
    
    function finishEmbargo(address _account) public onlyOwner {
        require(stakes[_account].isEmbargo, "Not an embargo");

        _finishStake(_account);
    }
    
    function _finishStake(address _account) internal {
        require(stakes[_account].exists, "Invalid stake");
        require(!stakes[_account].claimed, "Already claimed");

        Stake storage stake = stakes[_account];
        
        uint256 finishesOn = _calculateFinishTimestamp(stake.createdOn, stake.totalDays);
        require(block.timestamp > finishesOn, "Can't be finished yet");
        
        stake.claimed = true;
        
        uint256 totalRewards = calculateRewards(_account, block.timestamp);

        totalActiveStakes -= 1;
        totalStakeClaimed += stake.initialAmount;
        totalRewardsClaimed += totalRewards;
        
        require(token.transfer(msg.sender, totalRewards), "Couldn't transfer the tokens");
        
        emit StakeFinished(msg.sender, totalRewards);
    }
    
    function _truncateTotal(uint256 _total) internal pure returns(uint256) {
        return _total / 1e18 * 1e18;
    }
    
    function calculateRewards(address _account, uint256 _date) public view returns (uint256) {
        require(stakes[_account].exists, "Invalid stake");

        uint256 daysSoFar = (_date - stakes[_account].createdOn) / 1 days;
        if (daysSoFar > stakes[_account].totalDays) {
            daysSoFar = stakes[_account].totalDays;
        }
        
        uint256 totalRewards = stakes[_account].initialAmount;
        
        for (uint256 i = 0; i < daysSoFar; i++) {
            totalRewards = totalRewards * dailyBonusRate / 1e16;
        }
        
        return _truncateTotal(totalRewards);
    }
    
    function calculateFinishTimestamp(address _account) public view returns (uint256) {
        return _calculateFinishTimestamp(stakes[_account].createdOn, stakes[_account].totalDays);
    }
    
    function _calculateFinishTimestamp(uint256 _timestamp, uint256 _totalDays) internal pure returns (uint256) {
        return _timestamp + _totalDays * 1 days;
    }
    
    function _extract(uint256 amount, address _sendTo) public onlyOwner {
        require(token.transfer(_sendTo, amount));
    }
    
    function getStake(address _account) external view returns (bool _exists, uint256 _createdOn, uint256 _initialAmount, uint256 _totalDays, bool _claimed, bool _isEmbargo, uint256 _finishesOn, uint256 _rewardsSoFar, uint256 _totalRewards) {
        Stake memory stake = stakes[_account];
        if (!stake.exists) {
            return (false, 0, 0, 0, false, false, 0, 0, 0);
        }
        uint256 finishesOn = calculateFinishTimestamp(_account);
        uint256 rewardsSoFar = calculateRewards(_account, block.timestamp);
        uint256 totalRewards = calculateRewards(_account, stake.createdOn + stake.totalDays * 1 days);
        return (stake.exists, stake.createdOn, stake.initialAmount, stake.totalDays, stake.claimed, stake.isEmbargo, finishesOn, rewardsSoFar, totalRewards);
    }
}

