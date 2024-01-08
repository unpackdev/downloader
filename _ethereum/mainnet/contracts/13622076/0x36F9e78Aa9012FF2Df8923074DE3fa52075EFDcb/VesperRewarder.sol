// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IMasterChefV2.sol";
import "./IRewarder.sol";

/// @title Vesper's double incentive Sushi pool rewarder contract
contract VesperRewarder is IRewarder, Ownable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 lpAmount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // This value is used as a snapshot of the amount of VSP entitled to the user in some point in time
        uint256 unpaidRewards; // The amount not payed due to low VSP balance
    }

    struct PoolInfo {
        uint256 accVspPerShare; // Accumulated VSP per share, times 1e12
        uint256 lastRewardTime; // Last block number that VSP distribution occurs
    }

    PoolInfo public poolInfo;

    mapping(address => UserInfo) public userInfo;

    IERC20 public immutable vspToken;

    IERC20 public immutable lpToken;

    address public immutable masterChefV2;

    uint256 public rewardPerSecond;

    /// @notice Emitted when `onSushiReward` function is called
    event OnRewardCalled(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);

    /// @notice Emitted when pool info is updated
    event PoolInfoUpdated(uint256 lastRewardTime, uint256 lpSupply, uint256 accVspPerShare);

    /// @notice Emitted when rewardPerSecond is updated
    event RewardPerSecondUpdated(uint256 rewardPerSecond);

    /**
     * @dev Throw when caller isn't the MasterChefV2 contract */
    modifier onlyMasterChefV2() {
        require(msg.sender == masterChefV2, "caller-is-not-masterchef-v2");
        _;
    }

    /**
     * @dev Throws when pool id is not valid
     */
    modifier onlyIfValidPoolId(uint256 _pid) {
        require(IMasterChefV2(masterChefV2).lpToken(_pid) == lpToken, "invalid-pid");
        _;
    }

    constructor(
        address _masterChefV2,
        IERC20 _vspToken,
        uint256 _rewardPerSecond,
        IERC20 _lpToken
    ) {
        masterChefV2 = _masterChefV2;
        vspToken = _vspToken;
        rewardPerSecond = _rewardPerSecond;
        lpToken = _lpToken;
    }

    /**
     * @notice Update reward variables
     */
    modifier updatePoolInfo() {
        if (block.timestamp > poolInfo.lastRewardTime) {
            uint256 _newAccVspPerShare = _updatedAccVspPerShare();

            if (_newAccVspPerShare != poolInfo.accVspPerShare) {
                poolInfo.accVspPerShare = _newAccVspPerShare;
            }

            poolInfo.lastRewardTime = block.timestamp;
            emit PoolInfoUpdated(poolInfo.lastRewardTime, lpToken.balanceOf(masterChefV2), poolInfo.accVspPerShare);
        }
        _;
    }

    /**
     * @notice Trigger function called by the MasterChefV2 contract that will send VSP rewards to the user
     * @dev Inherited from IRewarder
     */
    function onSushiReward(
        uint256 _pid,
        address _user,
        address _recipient,
        uint256, /*sushiAmount*/
        uint256 _updateLpAmount
    ) external override onlyMasterChefV2 onlyIfValidPoolId(_pid) updatePoolInfo {
        UserInfo storage _userInfo = userInfo[_user];

        uint256 _pending;

        // Use current `lpAmount` to distribute pending rewards
        if (_userInfo.lpAmount > 0) {
            _pending = _calculatePendingReward(_user, poolInfo.accVspPerShare);

            uint256 _balance = vspToken.balanceOf(address(this));
            if (_pending > _balance) {
                vspToken.safeTransfer(_recipient, _balance);
                _userInfo.unpaidRewards = _pending - _balance;
            } else {
                vspToken.safeTransfer(_recipient, _pending);
                _userInfo.unpaidRewards = 0;
            }
        }

        // Save `_updateLpAmount` and use it to calculate `rewardDebt`
        _userInfo.lpAmount = _updateLpAmount;
        _userInfo.rewardDebt = (_updateLpAmount * poolInfo.accVspPerShare) / 1e18;

        emit OnRewardCalled(_user, _pid, _pending - _userInfo.unpaidRewards, _recipient);
    }

    /**
     * @notice Calculate the `accVspPerShare` value according to the current state (i.e. timestamp and total LP staked)
     * This value means how much of VSP we distribute for each SLP staked
     */
    function _updatedAccVspPerShare() private view returns (uint256 _accVspPerShare) {
        _accVspPerShare = poolInfo.accVspPerShare;

        if (block.timestamp > poolInfo.lastRewardTime) {
            uint256 _lpSupply = lpToken.balanceOf(masterChefV2);

            if (_lpSupply > 0) {
                uint256 _timeSinceLastReward = block.timestamp - poolInfo.lastRewardTime;
                uint256 _vspReward = _timeSinceLastReward * rewardPerSecond;
                _accVspPerShare += (_vspReward * 1e18) / _lpSupply;
            }
        }
    }

    /**
     * @notice Calculate pending reward amount to distribute to a user
     * The pending reward is in essence the differente between the old and new `rewardDebt` values
     */
    function _calculatePendingReward(address _user, uint256 _accVspPerShare) private view returns (uint256 _pending) {
        UserInfo memory _userInfo = userInfo[_user];
        _pending = ((_userInfo.lpAmount * _accVspPerShare) / 1e18) - _userInfo.rewardDebt + _userInfo.unpaidRewards;
    }

    /**
     * @notice Check pending rewards for a given user
     */
    function pendingToken(address _user) public view returns (uint256 _pending) {
        uint256 _accVspPerShare = _updatedAccVspPerShare();
        _pending = _calculatePendingReward(_user, _accVspPerShare);
    }

    /**
     * @notice Check pending rewards for a given user
     * @dev Inherited from IRewarder
     */
    function pendingTokens(
        uint256, /*pid*/
        address user,
        uint256 /*sushiAmount*/
    ) external view override returns (IERC20[] memory _rewardTokens, uint256[] memory _rewardAmounts) {
        _rewardTokens = new IERC20[](1);
        _rewardTokens[0] = vspToken;

        _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = pendingToken(user);
    }

    /**
     * @notice Update the amount of VSP distribuited per second
     * @dev Only owner can call this
     */
    function updateRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
        rewardPerSecond = _rewardPerSecond;
        emit RewardPerSecondUpdated(_rewardPerSecond);
    }
}
