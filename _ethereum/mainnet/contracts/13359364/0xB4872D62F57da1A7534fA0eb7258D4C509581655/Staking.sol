// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

contract Staking is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");

    /**
     * @notice Staker contains info related to each staker
     * @param amount amount of tokens currently staked to the contract
     * @param rewardAllowed allowed  amount of reward tokens
     * @param rewardDebt value needed for correct calculation staker's share
     * @param distributed amount of distributed earned tokens
     */
    struct Staker {
        uint256 amount;
        uint256 rewardAllowed;
        uint256 rewardDebt;
        uint256 distributed;
        uint256 referralClaimed;
        string account;
    }

    /**
     * @notice StakeInfo contains info related to stake
     * @param startTime
     * @param distributionTime
     * @param rewardTotal
     * @param totalStaked
     * @param totalDistributed
     * @param stakeTokenAddress
     * @param rewardTokenAddress
     */
    struct StakeInfo {
        uint256 startTime;
        uint256 distributionTime;
        uint256 rewardTotal;
        uint256 minStake;
        uint256 maxStake;
        uint256 totalStaked;
        uint256 totalDistributed;
        address tokenAddress;
        uint256 apy;
    }

    /// @notice Periods of staking configuration variables
    uint256 public startTime;
    /// @notice Rewards distribution time
    uint256 public distributionTime;
    /// @notice Total rewards per distribution time
    uint256 public rewardTotal;
    /// @notice Total staked amount
    uint256 public totalStaked;
    /// @notice Total distributed tokens
    uint256 public totalDistributed;
    /// @notice Tokens per stake amount
    uint256 public tokensPerStake;
    /// @notice Produced rewards
    uint256 public rewardProduced;
    /// @notice ERC20 token staked to the contract and earned by stakers as reward.
    IERC20 public token;
    /// @notice Minimum tokens amount for staking
    uint256 public minStake;
    /// @notice Maximum tokens amount for staking
    uint256 public maxStake;

    uint256 public referralClaimed;

    /// @notice Stakers info by token holders.
    mapping(address => Staker) public stakes;
    mapping(bytes32 => bool) referralPayments;

    event Staked(
        uint256 amount,
        uint256 time,
        address indexed owner,
        string account
    );
    event Claimed(
        uint256 amount,
        uint256 time,
        address indexed owner,
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
        string account
    );

    constructor(
        uint256 _startTime,
        uint256 _distributionTime,
        uint256 _rewardTotal,
        uint256 _minStake,
        uint256 _maxStake,
        address _token
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        startTime = _startTime;
        distributionTime = _distributionTime;
        rewardTotal = _rewardTotal;
        minStake = _minStake;
        maxStake = _maxStake;
        token = IERC20(_token);
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
     * Parameters:
     *
     * - `_amount` - stake amount
     */
    function stake(uint256 _amount, string memory account)
        external
        nonReentrant
    {
        require(
            block.timestamp > startTime,
            "DAOvc Staking: Staking time has not come yet"
        );
        require(
            block.timestamp <= startTime + distributionTime,
            "DAOvc Staking: Staking time is over"
        );
        require(
            _amount >= minStake,
            "DAOvc Staking: Staking amount is less then required"
        );
        Staker storage staker = stakes[msg.sender];
        require(
            totalStaked + _amount <= maxStake,
            "DAOvc Staking: Staking amount is more then required"
        );
        if (totalStaked > 0) {
            update();
        }
        if (staker.amount == 0) {
            staker.account = account;
        }
        staker.rewardDebt += (_amount * tokensPerStake) / 1e20;
        totalStaked += _amount;
        staker.amount += _amount;
        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(_amount, block.timestamp, msg.sender, staker.account);
    }

    /**
     * @dev unstake - return staked amount
     *
     * Parameters:
     *
     * - `_amount` - stake amount
     */
    function unstake(uint256 _amount) external nonReentrant {
        Staker storage staker = stakes[msg.sender];
        require(
            block.timestamp >= startTime + distributionTime,
            "DAOvc Staking: It's not time to unstake tokens yet"
        );
        require(
            _amount <= staker.amount,
            "DAOvc Staking: Not enough tokens to unstake"
        );
        update();
        staker.rewardAllowed += (_amount * tokensPerStake) / 1e20;
        staker.amount -= _amount;
        totalStaked -= _amount;
        token.safeTransfer(msg.sender, _amount);
        emit Unstaked(_amount, block.timestamp, msg.sender, staker.account);
    }

    /**
     * @dev claim available rewards
     */
    function claim() external nonReentrant {
        if (totalStaked > 0) {
            update();
        }
        uint256 reward = calcReward(msg.sender, tokensPerStake);
        require(reward > 0, "DAOvc Staking: Nothing to claim");
        stakes[msg.sender].distributed += reward;
        totalDistributed += reward;
        token.safeTransfer(msg.sender, reward);
        emit Claimed(
            reward,
            block.timestamp,
            msg.sender,
            stakes[msg.sender].account
        );
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
        stakes[msg.sender].referralClaimed += amount;
        IERC20(from).safeTransfer(msg.sender, amount);
        emit ReferralClaimed(amount, block.timestamp, msg.sender, stakes[msg.sender].account);
    }

    /**
     * @dev calcReward - calculates available reward
     */
    function calcReward(address _staker, uint256 _tps)
        private
        view
        returns (uint256 reward)
    {
        Staker storage staker = stakes[_staker];
        reward =
            ((staker.amount * _tps) / 1e20) +
            staker.rewardAllowed -
            staker.distributed -
            staker.rewardDebt;

        return reward;
    }

    /**
     * @dev getClaim - returns available reward of `_staker`
     */
    function getClaim(address _staker) public view returns (uint256 reward) {
        uint256 _tps = tokensPerStake;
        if (totalStaked > 0) {
            uint256 rewardProducedAtNow = produced();
            if (rewardProducedAtNow > rewardProduced) {
                uint256 producedNew = rewardProducedAtNow - rewardProduced;
                _tps += (producedNew * 1e20) / totalStaked;
            }
        }
        reward = calcReward(_staker, _tps);

        return reward;
    }

    /**
     * @dev Calculates the necessary parameters for staking
     *
     */
    function produced() private view returns (uint256) {
        return
            block.timestamp > (startTime + distributionTime)
                ? rewardTotal
                : (rewardTotal * (block.timestamp - startTime)) /
                    distributionTime;
    }

    function update() public {
        uint256 rewardProducedAtNow = produced();
        if (rewardProducedAtNow > rewardProduced) {
            uint256 producedNew = rewardProducedAtNow - rewardProduced;
            if (totalStaked > 0) {
                tokensPerStake += (producedNew * 1e20) / totalStaked;
            }
            rewardProduced = rewardProducedAtNow;
        }
    }

    /**
     * @dev Updates the minimum amount available to stake
     * @param _amount Minimal value of tokens to ba available to stake
     */
    function updateMinStake(uint256 _amount) external onlyAdmin {
        minStake = _amount;
    }

    /**
     * @dev Updates the minimum amount available to stake
     * @param _amount Minimal value of tokens to ba available to stake
     */
    function updateMaxStake(uint256 _amount) external onlyAdmin {
        maxStake = _amount;
    }

    /**
     * @dev Allows to update the value of distributed rewards
     * @param _startTime Specifeies the new value of start staking time
     */
    function setStartTime(uint256 _startTime) external onlyAdmin {
        require(
            block.timestamp < startTime,
            "DAOvc Staking: Staking time has already come"
        );
        startTime = _startTime;
    }

    /**
     * @dev Allows to update the daily reward parameter
     * @param _rewardTotal Specifeies the new daily reward value
     */
    function updateRewardTotal(uint256 _rewardTotal) external onlyAdmin {
        rewardTotal = _rewardTotal;
    }

    /**
     * @dev Allows to update 'tokens per stake' parameter
     * @param _tps Specifeies the new tokens per stake value
     */
    function updateTps(uint256 _tps) external onlyAdmin {
        tokensPerStake = _tps;
    }

    /**
     * @dev Allows to update the value of produced reward
     * @param _rewardProduced Specifeies the new value of rewards produced
     */
    function updateRewardProduced(uint256 _rewardProduced) external onlyAdmin {
        rewardProduced = _rewardProduced;
    }

    /**
     * @dev Allows to update the value of staked tokens
     * @param _totalStaked Specifeies the new value of totally staked tokens
     */
    function updateTotalStaked(uint256 _totalStaked) external onlyAdmin {
        totalStaked = _totalStaked;
    }

    /**
     * @dev Allows to update the value of distributed rewards
     * @param _totalDistributed Specifeies the new value of totally distributed rewards
     */
    function updateTotalDistributed(uint256 _totalDistributed)
        external
        onlyAdmin
    {
        totalDistributed = _totalDistributed;
    }

    /**
     * @dev updateStakerInfo - update user information
     */
    function updateStakerInfo(
        address _user,
        uint256 _amount,
        uint256 _rewardAllowed,
        uint256 _rewardDebt,
        uint256 _distributed,
        string memory _account
    ) external onlyAdmin {
        Staker storage staker = stakes[_user];
        staker.amount = _amount;
        staker.rewardAllowed = _rewardAllowed;
        staker.rewardDebt = _rewardDebt;
        staker.distributed = _distributed;
        staker.account = _account;
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

    /**
     * @dev getInfoByAddress - return information about the staker
     */
    function getInfoByAddress(address user)
        external
        view
        returns (
            uint256 staked_,
            uint256 claim_,
            uint256 _balance
        )
    {
        Staker storage staker = stakes[user];
        return (staker.amount, getClaim(user), token.balanceOf(user));
    }

    /**
     * @dev getStakingInfo - return information about the stake
     */
    function getStakingInfo() external view returns (StakeInfo memory info_) {
        info_ = StakeInfo({
            startTime: startTime,
            distributionTime: distributionTime,
            rewardTotal: rewardTotal,
            minStake: minStake,
            maxStake: maxStake,
            totalStaked: totalStaked,
            totalDistributed: totalDistributed,
            tokenAddress: address(token),
            apy: totalStaked > 0
                ? (produced() * 31104000e18) / (totalStaked * distributionTime)
                : 0
        });
        return info_;
    }
}
