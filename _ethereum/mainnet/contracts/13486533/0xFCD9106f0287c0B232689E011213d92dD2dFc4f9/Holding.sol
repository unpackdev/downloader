// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

contract Holding is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");

    enum StakeType {
        threeMonth,
        sixMonth,
        twelveMonth
    }

    /**
     * @notice Staker contains info related to each staker
     * @param amount amount of tokens currently staked to the contract
     * @param distributed amount of distributed earned tokens
     */
    struct Staker {
        uint256 amount;
        uint256 updatedAt;
        uint256 rewardProduced;
        uint256 rewardClaimed;
    }

    /**
     * @notice StakeInfo contains info related to stake
     * @param distributionTime Rewards distribution time
     * @param percent
     * @param totalStaked
     * @param totalDistributed
     * @param minStake Minimum tokens amount for staking
     * @param maxStake Maximum tokens amount for staking
     */
    struct StakeInfo {
        uint256 distributionTime;
        uint256 percent;
        uint256 totalStaked;
        uint256 totalDistributed;
        uint256 minStake;
        uint256 maxStake;
    }

    /// @notice if true users can claim rewards, else not 
    bool claimEnabled;
    /// @notice ERC20 token staked to the contract and earned by stakers as reward.
    IERC20 public token;
    /// @notice Periods of staking configuration variables
    uint256 public startTime;
 
    uint256 referralClaimed;

    /// @notice Stakers info by token holders.
    mapping(StakeType => mapping(address => Staker)) public stakes;
    mapping(StakeType => StakeInfo) public stakeInfo;
    mapping(bytes32 => bool) referralPayments;
    mapping(address => uint256) usersReferralClaimed;
    mapping(address => string) accounts;

    event Staked(
        uint256 amount,
        uint256 time,
        address indexed owner,
        StakeType stakeType,
        string account
    );
    event Claimed(
        uint256 amount,
        uint256 time,
        address indexed owner,
        StakeType stakeType,
        string account
    );
    event ReferralClaimed(
        uint256 amount,
        uint256 time,
        address indexed owner,
        string account
    );
    event Unstaked(
        uint256 amount,
        uint256 time,
        address indexed owner,
        StakeType stakeType,
        string account
    );

    constructor(
        uint256 _startTime,
        address _token,
        uint256[3] memory distributionTime,
        uint256[3] memory percent,
        uint256[3] memory minStake,
        uint256[3] memory maxStake
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(SERVICE_ROLE, ADMIN_ROLE);
        startTime = _startTime;
        token = IERC20(_token);
        for (uint256 i = 0; i < 3; i++) {
            stakeInfo[StakeType(i)].distributionTime = distributionTime[i];
            stakeInfo[StakeType(i)].percent = percent[i];
            stakeInfo[StakeType(i)].minStake = minStake[i];
            stakeInfo[StakeType(i)].maxStake = maxStake[i];
        }
        claimEnabled = true;
    }

    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "DAOvc Staking: you should have an admin role"
        );
        _;
    }

    /**
     * @dev stake `amount` of tokens to the contract
     *
     * @param stakeType - type of staking threeMonth, sixMonth, twelveMonth
     * @param amount - amount for stake
     * @param account - value for refferal calculations 
     */
    function stake(
        StakeType stakeType,
        uint256 amount,
        string memory account
    ) external nonReentrant {
        require(
            block.timestamp > startTime,
            "DAOvc Staking: Staking time has not come yet"
        );
        require(
            block.timestamp <=
                startTime + stakeInfo[stakeType].distributionTime,
            "DAOvc Staking: Staking time is over"
        );
        require(
            amount >= stakeInfo[stakeType].minStake,
            "DAOvc Staking: Staking amount is less then required"
        );
        Staker storage staker = stakes[stakeType][msg.sender];
        require(
            stakeInfo[stakeType].totalStaked + amount <=
                stakeInfo[stakeType].maxStake,
            "DAOvc Staking: Staking amount is more then required"
        );
        if (staker.amount == 0) {
            accounts[msg.sender] = account;
            staker.updatedAt = block.timestamp;
        }

        stakeInfo[stakeType].totalStaked += amount;
        staker.rewardProduced = produced(stakeType, msg.sender);
        staker.amount += amount;
        staker.updatedAt = block.timestamp;
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(
            amount,
            block.timestamp,
            msg.sender,
            stakeType,
            accounts[msg.sender]
        );
    }

    /**
     * @dev unstake - return staked amount
     *
     * @param stakeType - type of staking threeMonth, sixMonth, twelveMonth
     * @param amount - amount for unstake
     */
    function unstake(StakeType stakeType, uint256 amount)
        external
        nonReentrant
    {
        Staker storage staker = stakes[stakeType][msg.sender];
        require(
            block.timestamp >=
                startTime + stakeInfo[stakeType].distributionTime,
            "DAOvc Staking: It's not time to unstake tokens yet"
        );
        require(
            amount <= staker.amount,
            "DAOvc Staking: Not enough tokens to unstake"
        );
        stakeInfo[stakeType].totalStaked -= amount;
        staker.rewardProduced = produced(stakeType, msg.sender);
        staker.amount -= amount;
        staker.updatedAt = block.timestamp;
        token.safeTransfer(msg.sender, amount);
        emit Unstaked(
            amount,
            block.timestamp,
            msg.sender,
            stakeType,
            accounts[msg.sender]
        );
    }

    /**
     * @dev claim available rewards
     *
     * @param stakeType - type of staking threeMonth, sixMonth, twelveMonth
     */
    function claim(StakeType stakeType) external nonReentrant {
        require(claimEnabled, "DAOvc Staking: reward is not possible for claiming");
        Staker storage staker = stakes[stakeType][msg.sender];
        staker.rewardProduced = produced(stakeType, msg.sender);
        uint256 reward = staker.rewardProduced - staker.rewardClaimed;
        require(reward > 0, "DAOvc Staking: Nothing to claim");
        stakeInfo[stakeType].totalDistributed += reward;
        staker.rewardClaimed = staker.rewardProduced;
        staker.updatedAt = block.timestamp;
        token.safeTransfer(msg.sender, reward);
        emit Claimed(
            reward,
            block.timestamp,
            msg.sender,
            stakeType,
            accounts[msg.sender]
        );
    }

    /**
     * @dev calcReward - calculates available reward
     */
    function produced(StakeType stakeType, address _staker)
        private
        view
        returns (uint256 reward)
    {
        Staker storage staker = stakes[stakeType][_staker];
        reward =
            staker.rewardProduced +
            ((stakeInfo[stakeType].percent * staker.amount) *
                (block.timestamp - staker.updatedAt)) /
            stakeInfo[stakeType].distributionTime /
            1e20;
        return reward;
    }

    /**
     * @dev claim available rewards
     */
    function claimReferal(
        bytes32 hashedMessage,
        uint256 amount,
        uint256 sequence,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address from
    ) external nonReentrant {
        require(
            hasRole(SERVICE_ROLE, hashedMessage.recover(v, r, s)),
            "DAOvc Staking: Validator address is invalid or signature is faked"
        );
        bytes32 message = keccak256(
            abi.encodePacked(msg.sender, amount, sequence)
        );
        require(
            message.toEthSignedMessageHash() == hashedMessage,
            "DAOvc Staking: Incorrect hashed message"
        );
        require(
            !referralPayments[message],
            "DAOvc Staking: Duplicate transaction"
        );
        referralPayments[message] = true;
        referralClaimed += amount;
        usersReferralClaimed[msg.sender] += amount;
        IERC20(from).safeTransfer(msg.sender, amount);
        emit ReferralClaimed(
            amount,
            block.timestamp,
            msg.sender,
            accounts[msg.sender]
        );
    }

    // ---------------- ADMIN FUNCTIONS ---------------- // 
    /**
     * @dev Allows to update the value of distributed rewards
     * @param _startTime Specifeies the new value of start staking time
     */
    function setStartTime(uint256 _startTime) external onlyAdmin {
        require(
            block.timestamp < _startTime,
            "DAOvc Staking: Staking time has already come"
        );
        startTime = _startTime;
    }

    /**
     * @dev Allows to update the value of distribution time
     * @param distributionTime Specifeies the new value of totally staked tokens
     */
    function updateDistributionTime(
        StakeType stakeType,
        uint256 distributionTime
    ) external onlyAdmin {
        stakeInfo[stakeType].distributionTime = distributionTime;
    }

    /**
     * @dev Allows to update the value of staked tokens
     * @param percent Specifeies the new value of totally staked tokens
     */
    function updatePercent(StakeType stakeType, uint256 percent)
        external
        onlyAdmin
    {
        stakeInfo[stakeType].percent = percent;
    }

    /**
     * @dev Allows to update the value of staked tokens
     * @param _totalStaked Specifeies the new value of totally staked tokens
     */
    function updateTotalStaked(StakeType stakeType, uint256 _totalStaked)
        external
        onlyAdmin
    {
        stakeInfo[stakeType].totalStaked = _totalStaked;
    }

    /**
     * @dev Allows to update the value of distributed rewards
     * @param _totalDistributed Specifeies the new value of totally distributed rewards
     */
    function updateTotalDistributed(
        StakeType stakeType,
        uint256 _totalDistributed
    ) external onlyAdmin {
        stakeInfo[stakeType].totalDistributed = _totalDistributed;
    }
    
    /**
     * @dev Updates the minimum amount available to stake
     * @param _amount Minimal value of tokens to ba available to stake
     */
    function updateMinStake(StakeType stakeType, uint256 _amount)
        external
        onlyAdmin
    {
        stakeInfo[stakeType].minStake = _amount;
    }

    /**
     * @dev Updates the minimum amount available to stake
     * @param _amount Minimal value of tokens to ba available to stake
     */
    function updateMaxStake(StakeType stakeType, uint256 _amount)
        external
        onlyAdmin
    {
        stakeInfo[stakeType].maxStake = _amount;
    }
    
    /**
     * @dev updateStakerInfo - update user information
     */
    function updateStakerInfo(
        StakeType stakeType,
        address user,
        uint256 amount,
        uint256 updatedAt,
        uint256 rewardProduced,
        uint256 rewardClaimed,
        uint256 _referralClaimed,
        string memory account
    ) external onlyAdmin {
        stakes[stakeType][user] = Staker({
            amount: amount,
            updatedAt: updatedAt,
            rewardProduced: rewardProduced,
            rewardClaimed: rewardClaimed
        });
        accounts[user] = account;
        usersReferralClaimed[msg.sender] = _referralClaimed;
    }

    /**
     * @dev Removes any token from the contract by its address
     * @param _token Token's address
     * @param _to Recipient address
     * @param _amount An amount to be removed from the contract
     */
    function removeLiquidity(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyAdmin {
        require(_token != address(0), "Invalid token address");
        require(_to != address(0), "Invalid recipient address");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /** @dev function controls can users claim reward or not 
     * @param _enableClaim - boolean var, true - users can claim rewards,
     *                       false - users cannot claim rewards
     */
    function claimControl(
        bool _enableClaim
    ) external onlyAdmin {
        claimEnabled = _enableClaim;
    }
    
    // ---------------- VIEW FUNCTIONS ---------------- // 
    /**
     * @dev getClaim - returns available reward of `_staker`
     */
    function getClaim(StakeType stakeType, address user)
        public
        view
        returns (uint256 reward)
    {
        return
            produced(stakeType, user) - stakes[stakeType][user].rewardClaimed;
    }    

    function getStakingInfo(
        StakeType _stakeType
    ) external view returns(
        StakeInfo memory staking_
    ) {
        return staking_ = stakeInfo[_stakeType];
    }
    /**
     * @dev getInfoByAddress - return information about the staker
     */
    function getInfoByAddress(StakeType stakeType, address user)
        external
        view
        returns (
            uint256 staked,
            uint256 availableClaim,
            uint256 rewardClaimed,
            uint256 referralClaimed_,
            uint256 balance
        )
    {
        return (
            stakes[stakeType][user].amount,
            getClaim(stakeType, user),
            stakes[stakeType][user].rewardClaimed,
            usersReferralClaimed[user],
            token.balanceOf(user)
        );
    }
}
