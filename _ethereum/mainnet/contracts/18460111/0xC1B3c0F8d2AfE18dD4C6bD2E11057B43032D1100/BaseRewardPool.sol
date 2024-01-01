// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";

import "./IMasterMagpie.sol";
import "./IBaseRewardPool.sol";

/// @title A contract for managing rewards for a pool
/// @author Magpie Team
/// @notice You can use this contract for getting informations about rewards for a specific pools
contract BaseRewardPool is Ownable, IBaseRewardPool {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    address public immutable stakingToken;
    address public immutable operator;          // master magpie

    address[] public rewardTokens;

    struct Reward {
        address rewardToken;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
        uint256 historicalRewards;
    }

    mapping(address => Reward) public rewards;                           // [rewardToken]
    // amount by [rewardToken][account], 
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;                 
    mapping(address => mapping(address => uint256)) public userRewards;  // amount by [rewardToken][account]
    mapping(address => bool) public isRewardToken;
    mapping(address => bool) public managers;

    /* ============ Events ============ */

    event RewardAdded(uint256 _reward, address indexed _token);
    event Staked(address indexed _user, uint256 _amount);
    event Withdrawn(address indexed _user, uint256 _amount);
    event RewardPaid(address indexed _user, address indexed _receiver, uint256 _reward, address indexed _token);
    event ManagerUpdated(address indexed _manager, bool _allowed);

    /* ============ Errors ============ */

    error OnlyManager();
    error OnlyMasterMagpie();
    error NotAllowZeroAddress();
    error MustBeRewardToken();

    /* ============ Constructor ============ */

    constructor(
        address _stakingToken,
        address _rewardToken,
        address _masterMagpie,
        address _rewardManager
    ) {
        if(
            _stakingToken == address(0) ||
            _masterMagpie  == address(0) ||
            _rewardManager  == address(0)
        ) revert NotAllowZeroAddress();

        stakingToken = _stakingToken;
        operator = _masterMagpie;

        if (_rewardToken != address(0)) {
            rewards[_rewardToken] = Reward({
                rewardToken: _rewardToken,
                rewardPerTokenStored: 0,
                queuedRewards: 0,
                historicalRewards: 0
            });
            rewardTokens.push(_rewardToken);
        }

        isRewardToken[_rewardToken] = true;
        managers[_rewardManager] = true;
    }

    /* ============ Modifiers ============ */

    modifier updateReward(address _account) {
        _updateFor(_account);
        _;
    }

    modifier onlyManager() {
        if (!managers[msg.sender])
            revert OnlyManager();
        _;
    }

    modifier onlyMasterMagpie() {
        if (msg.sender != operator)
            revert OnlyMasterMagpie();
        _;
    }

    /* ============ External Getters ============ */

    /// @notice Returns decimals of reward token
    /// @param _rewardToken Address of reward token
    /// @return Returns decimals of reward token
    function rewardDecimals(address _rewardToken)
        public
        view
        returns (uint256)
    {
        return IERC20Metadata(_rewardToken).decimals();
    }

    /// @notice Returns decimals of staking token
    /// @return Returns decimals of staking token
    function stakingDecimals() public override view returns (uint256) {
        return IERC20Metadata(stakingToken).decimals();
    }

    /// @notice Returns current amount of staked tokens
    /// @return Returns current amount of staked tokens
    function totalStaked() external override virtual view returns (uint256) {
        return IERC20(stakingToken).balanceOf(operator);
    }

    /// @notice Returns amount of staked tokens in master magpie by account
    /// @param _account Address account
    /// @return Returns amount of staked tokens by account
    function balanceOf(address _account) public override virtual view returns (uint256) {
        (uint256 staked, ) =  IMasterMagpie(operator).stakingInfo(stakingToken, _account);
        return staked;
    }

    /// @notice Returns amount of reward token per staking tokens in pool
    /// @param _rewardToken Address reward token
    /// @return Returns amount of reward token per staking tokens in pool
    function rewardPerToken(address _rewardToken)
        public
        override
        view
        returns (uint256)
    {
        return rewards[_rewardToken].rewardPerTokenStored;
    }

    function rewardTokenInfos()
        override
        external
        view
        returns
        (
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols
        )
    {
        uint256 rewardTokensLength = rewardTokens.length;
        bonusTokenAddresses = new address[](rewardTokensLength);
        bonusTokenSymbols = new string[](rewardTokensLength);
        for (uint256 i; i < rewardTokensLength; i++) {
            bonusTokenAddresses[i] = rewardTokens[i];
            bonusTokenSymbols[i] = IERC20Metadata(address(bonusTokenAddresses[i])).symbol();
        }
    }

    /// @notice Returns amount of reward token earned by a user
    /// @param _account Address account
    /// @param _rewardToken Address reward token
    /// @return Returns amount of reward token earned by a user
    function earned(address _account, address _rewardToken)
        public
        override
        view
        returns (uint256)
    {
        return (
            (((balanceOf(_account) *
                (rewardPerToken(_rewardToken) -
                    userRewardPerTokenPaid[_rewardToken][_account])) /
                (10**stakingDecimals())) + userRewards[_rewardToken][_account])
        );
    }

    /// @notice Returns amount of all reward tokens
    /// @param _account Address account
    /// @return pendingBonusRewards as amounts of all rewards.
    function allEarned(address _account)
        external
        override
        view
        returns (
            uint256[] memory pendingBonusRewards
        )
    {
        uint256 length = rewardTokens.length;
        pendingBonusRewards = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            pendingBonusRewards[i] = earned(_account, rewardTokens[i]);
        }

        return pendingBonusRewards;
    }

    function getStakingToken() external view returns (address) {
        return stakingToken;
    }

    /* ============ External Functions ============ */

    /// @notice Updates the reward information for one account
    /// @param _account Address account
    function updateFor(address _account) override external {
        _updateFor(_account);
    }

    /// @notice Calculates and sends reward to user. Only callable by masterMagpie
    /// @param _account Address account
    function getReward(address _account, address _receiver)
        override
        public
        onlyMasterMagpie
        updateReward(_account)
        returns (bool)
    {
        uint256 length = rewardTokens.length;
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            uint256 reward = userRewards[rewardToken][_account]; // updated during updateReward modifier
            if (reward > 0) {
                userRewards[rewardToken][_account] = 0;
                IERC20(rewardToken).safeTransfer(_receiver, reward);
                emit RewardPaid(_account, _receiver, reward, rewardToken);
            }
        }

        return true;
    }

    function getRewards(address _account, address _receiver, address[] memory _rewardTokens) override external {

    }

    function getRewardLength() external view returns(uint256) {
        return rewardTokens.length;
    }

    /* ============ Admin Functions ============ */

    function updateManager(address _rewardManager, bool _allowed) external onlyOwner {
        managers[_rewardManager] = _allowed;

        emit ManagerUpdated(_rewardManager, managers[_rewardManager]);
    }

    /// @notice Sends new rewards to be distributed to the users staking. Only callable by manager
    /// @param _amountReward Amount of reward token to be distributed
    /// @param _rewardToken Address reward token
    function queueNewRewards(uint256 _amountReward, address _rewardToken)
        override
        external
        onlyManager
        returns (bool)
    {
        if (!isRewardToken[_rewardToken]) {
            rewardTokens.push(_rewardToken);
            isRewardToken[_rewardToken] = true;
        }

        _provisionReward(_amountReward, _rewardToken);
        return true;
    }

    /// @notice Sends new rewards to be distributed to the users staking. Only possible to donate already registered token
    /// @param _amountReward Amount of reward token to be distributed
    /// @param _rewardToken Address reward token
    function donateRewards(uint256 _amountReward, address _rewardToken) external {
        if (!isRewardToken[_rewardToken])
            revert MustBeRewardToken();

        _provisionReward(_amountReward, _rewardToken);
    }

    /* ============ Internal Functions ============ */

    function _updateFor(address _account) internal {
        uint256 length = rewardTokens.length;
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            userRewards[rewardToken][_account] = earned(_account, rewardToken);
            userRewardPerTokenPaid[rewardToken][_account] = rewardPerToken(rewardToken);
        }
    }

    function _provisionReward(uint256 _amountReward, address _rewardToken) internal {
        IERC20(_rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amountReward
        );
        Reward storage rewardInfo = rewards[_rewardToken];
        rewardInfo.historicalRewards =
            rewardInfo.historicalRewards +
            _amountReward;
        if (this.totalStaked() == 0) {
            rewardInfo.queuedRewards += _amountReward;
        } else {
            if (rewardInfo.queuedRewards > 0) {
                _amountReward += rewardInfo.queuedRewards;
                rewardInfo.queuedRewards = 0;
            }
            rewardInfo.rewardPerTokenStored =
                rewardInfo.rewardPerTokenStored +
                (_amountReward * 10**stakingDecimals()) /
                this.totalStaked();
        }
        emit RewardAdded(_amountReward, _rewardToken);
    }
}