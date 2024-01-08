//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./AccessLevel.sol";
import "./SafeMath.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";

contract StakingV2 is AccessLevel {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    struct StakingInfo{
        address owner;
        uint id;
        uint timeToUnlock;
        uint stakingTime;
        uint tokensStaked;
        uint tokensStakedWithBonus;
    }

    uint private constant DIVISOR = 10000;
    uint public MAX_LOSS;
    uint public BURN_PERCENTAGE;
    uint public RETURN_TO_POOL_PERCENTAGE;
    uint private constant SECONDS_IN_A_YEAR = 31556926;
    address public mainTokenAddress;
    address public burnAddress;
    uint public totalTokensStaked;
    uint public totalTokensStakedWithBonusTokens;
    uint public stakingRewardPercentageAnualised;
    bool public stakingEnabled;
    uint public rewardTokensLeft;
    uint public uniqueAddressesStaked;
    mapping(address => uint) public tokensStakedByAddress;
    mapping(address => uint) public tokensStakedWithBonusByAddress;
    mapping(uint => uint) public bonusTokenMultiplier;
    mapping(address => mapping(uint => StakingInfo)) public stakingInfoForAddress;
    mapping(address => uint) public stakingNonce;
    
    event Stake(uint256 stakeId, address staker);
    event Unstake(uint256 stakeId, address unstaker);

    function initialize(address _tokenAddress, address _owner, uint _stakingRewardPercentageAnualised, address _burnAddress) initializer public {
        __AccessLevel_init(_owner);
        mainTokenAddress = _tokenAddress;
        stakingRewardPercentageAnualised = _stakingRewardPercentageAnualised;
        stakingEnabled = true;
        burnAddress = _burnAddress;
        MAX_LOSS = 7500;
        BURN_PERCENTAGE = 5000;
        RETURN_TO_POOL_PERCENTAGE = 5000;
    }

    /**
    @dev Stakes the user tokens for teh amount of time desired (chosen from teh available lock times)
    @param _amount is the amount of tkens the user wants to stake
    @param _lockTime is the amount of time the tokens will be staked for
     */
    function stake(uint _amount, uint _lockTime) public {
        require(stakingEnabled , "STAKING_DISABLED");
        require(_amount > 0, "CANNOT_STAKE_0");
        require(bonusTokenMultiplier[_lockTime] > 0, "LOCK_TIME_ERROR");

        if(stakingNonce[msg.sender] == 0){
            uniqueAddressesStaked++;
        }

        StakingInfo storage data = stakingInfoForAddress[msg.sender][stakingNonce[msg.sender]];
        data.owner = msg.sender;
        data.stakingTime = block.timestamp;
        data.tokensStaked = _amount;
        data.timeToUnlock = block.timestamp + _lockTime;
        data.tokensStakedWithBonus = _amount * bonusTokenMultiplier[_lockTime] / DIVISOR;
        data.id = stakingNonce[msg.sender];

        totalTokensStaked += _amount;
        totalTokensStakedWithBonusTokens += data.tokensStakedWithBonus;
        tokensStakedByAddress[msg.sender] += _amount;
        tokensStakedWithBonusByAddress[msg.sender] += data.tokensStakedWithBonus;

        emit Stake(stakingNonce[msg.sender], msg.sender);
        stakingNonce[msg.sender]++;
        // transfer the tokens
        IERC20Upgradeable(mainTokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function setBonusMultiplier(uint[] calldata _durations, uint[] calldata _mutiplier) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for(uint256 i = 0; i < _durations.length; i++) {
            bonusTokenMultiplier[_durations[i]] = _mutiplier[i];
        }
    }
    
    function setStakingEnabled(bool _stakingEnabled) public onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingEnabled = _stakingEnabled;
    }

    function setMaxLoss(uint _maxLoss) public onlyRole(DEFAULT_ADMIN_ROLE) {
        MAX_LOSS = _maxLoss;
    }

    function setBurnAddress(address _burnAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        burnAddress = _burnAddress;
    }

    function setBurnPercentage(uint _burnPercentage) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BURN_PERCENTAGE = _burnPercentage;
        RETURN_TO_POOL_PERCENTAGE = DIVISOR - BURN_PERCENTAGE;
    }

    function setReturnToPoolPercentage(uint _returnToPoolPercentage) public onlyRole(DEFAULT_ADMIN_ROLE) {
        RETURN_TO_POOL_PERCENTAGE = _returnToPoolPercentage;
        BURN_PERCENTAGE = DIVISOR - RETURN_TO_POOL_PERCENTAGE;
    }

    function setStakingRewardPercentageAnualised(uint _stakingRewardPercentageAnualised) public onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingRewardPercentageAnualised = _stakingRewardPercentageAnualised;
    }

    function addRewardTokens(uint _amount) public {
        rewardTokensLeft += _amount;
        IERC20Upgradeable(mainTokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
    @dev Returns all the user stakes
     */
    function getAllAddressStakes(address userAddress) public view returns(StakingInfo[] memory)
    {
        StakingInfo[] memory stakings = new StakingInfo[](stakingNonce[userAddress]);
        for (uint i = 0; i < stakingNonce[userAddress]; i++) {
            StakingInfo storage staking = stakingInfoForAddress[userAddress][i];
            stakings[i] = staking;
        }
        return stakings;
    }

    /**
    @dev Unstakes the users stake from the system
    @param _stakeId is the id of the stake the user wants to remove
     */
    function unstake(uint _stakeId) public {
        StakingInfo storage info = stakingInfoForAddress[msg.sender][_stakeId];
        require(info.tokensStaked > 0, "Already unstaked");

        uint rewardPercentage = (block.timestamp - info.stakingTime) * stakingRewardPercentageAnualised / SECONDS_IN_A_YEAR;
        uint rewardsForStaking = rewardPercentage * info.tokensStakedWithBonus / DIVISOR;
        uint tokensStaked = info.tokensStaked;
        totalTokensStaked -= info.tokensStaked;
        totalTokensStakedWithBonusTokens -= info.tokensStakedWithBonus;
        tokensStakedByAddress[msg.sender] -= info.tokensStaked;
        tokensStakedWithBonusByAddress[msg.sender] -= info.tokensStakedWithBonus;
        
        if(info.timeToUnlock > block.timestamp) {
            uint maxTime = info.timeToUnlock - info.stakingTime;
            uint lossPercentage = MAX_LOSS - (block.timestamp - info.stakingTime) * MAX_LOSS / maxTime;
            uint tokensLost = lossPercentage * info.tokensStaked / DIVISOR;
            uint tokensToBurn = tokensLost * BURN_PERCENTAGE / DIVISOR;
            rewardTokensLeft += tokensLost * RETURN_TO_POOL_PERCENTAGE / DIVISOR;
            
            delete stakingInfoForAddress[msg.sender][_stakeId];
            
            emit Unstake(_stakeId, msg.sender);
            IERC20Upgradeable(mainTokenAddress).safeTransfer(burnAddress, tokensToBurn);
            IERC20Upgradeable(mainTokenAddress).safeTransfer(msg.sender, tokensStaked - tokensLost  + rewardsForStaking);
        } else {
            delete stakingInfoForAddress[msg.sender][_stakeId];
            emit Unstake(_stakeId, msg.sender);
            IERC20Upgradeable(mainTokenAddress).safeTransfer(msg.sender, tokensStaked + rewardsForStaking);
        }
    }

}
