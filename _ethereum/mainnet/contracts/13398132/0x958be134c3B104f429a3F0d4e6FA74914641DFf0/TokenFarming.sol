// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./PausableUpgradeable.sol";

import "./Globals.sol";

contract TokenFarming is OwnableUpgradeable, PausableUpgradeable {
    IERC20 public stakeToken;
    IERC20 public distributionToken;

    uint256 public rewardPerBlock;

    uint256 public cumulativeSum;
    uint256 public lastUpdate;

    uint256 public totalPoolStaked;

    uint256 public startDate;

    struct UserInfo {
        uint256 stakedAmount;
        uint256 lastCumulativeSum;
        uint256 aggregatedReward;
    }

    mapping(address => UserInfo) public userInfos;

    event TokensStaked(address _staker, uint256 _stakeAmount);
    event TokensWithdrawn(address _staker, uint256 _withdrawAmount);
    event RewardsClaimed(address _claimer, uint256 _rewardsAmount);

    function initTokenFarming(
        address _stakeToken,
        address _distributioToken,
        uint256 _rewardPerBlock
    ) external initializer() {
        __Pausable_init_unchained();
        __Ownable_init();
        stakeToken = IERC20(_stakeToken);
        distributionToken = IERC20(_distributioToken);
        rewardPerBlock = _rewardPerBlock;
        startDate = block.timestamp;
    }

    modifier updateRewards() {
        _updateUserRewards(_updateCumulativeSum());
        _;
    }

    function updateRewardPerBlock(uint256 _newRewardPerBlock) external onlyOwner {
        _updateCumulativeSum();
        rewardPerBlock = _newRewardPerBlock;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function stake(uint256 _stakeAmount) external updateRewards whenNotPaused() {
        userInfos[msg.sender].stakedAmount += _stakeAmount;
        totalPoolStaked += _stakeAmount;

        stakeToken.transferFrom(msg.sender, address(this), _stakeAmount);

        emit TokensStaked(msg.sender, _stakeAmount);
    }

    function withdrawFunds(uint256 _amountToWithdraw) public updateRewards {
        uint256 _currentStakedAmount = userInfos[msg.sender].stakedAmount;

        require(
            _currentStakedAmount >= _amountToWithdraw,
            "TokenFarming: Not enough staked tokens to withdraw"
        );

        userInfos[msg.sender].stakedAmount = _currentStakedAmount - _amountToWithdraw;
        totalPoolStaked -= _amountToWithdraw;

        stakeToken.transfer(msg.sender, _amountToWithdraw);

        emit TokensWithdrawn(msg.sender, _amountToWithdraw);
    }

    function claimRewards() public updateRewards {
        uint256 _currentRewards = _applySlashing(userInfos[msg.sender].aggregatedReward);

        require(_currentRewards > 0, "TokenFarming: Nothing to claim");

        delete userInfos[msg.sender].aggregatedReward;

        distributionToken.transfer(msg.sender, _currentRewards);

        emit RewardsClaimed(msg.sender, _currentRewards);
    }

    function claimAndWithdraw() external {
        withdrawFunds(userInfos[msg.sender].stakedAmount);
        claimRewards();
    }

    /// @dev prices with the same precision
    function getAPY(
        address _userAddr,
        uint256 _stakeTokenPrice,
        uint256 _distributionTokenPrice
    ) external view returns (uint256 _resultAPY) {
        uint256 _userStakeAmount = userInfos[_userAddr].stakedAmount;

        if (_userStakeAmount > 0) {
            uint256 _newCumulativeSum =
                _getNewCumulativeSum(
                    rewardPerBlock,
                    totalPoolStaked,
                    cumulativeSum,
                    BLOCKS_PER_YEAR
                );

            uint256 _totalReward =
                ((_newCumulativeSum - userInfos[_userAddr].lastCumulativeSum) * _userStakeAmount) /
                    DECIMAL;

            _resultAPY =
                (_totalReward * _distributionTokenPrice * DECIMAL) /
                (_stakeTokenPrice * _userStakeAmount);
        }
    }

    function getTotalAPY(uint256 _stakeTokenPrice, uint256 _distributionTokenPrice)
        external
        view
        returns (uint256)
    {
        uint256 _totalPool = totalPoolStaked;

        if (_totalPool > 0) {
            uint256 _totalRewards = distributionToken.balanceOf(address(this));
            return
                (_totalRewards * _distributionTokenPrice * DECIMAL) /
                (_totalPool * _stakeTokenPrice);
        }
        return 0;
    }

    function _applySlashing(uint256 _rewards) private view returns (uint256) {
        if (block.timestamp < startDate + 150 days) {
            return (_rewards * (block.timestamp - startDate)) / 150 days;
        }

        return _rewards;
    }

    function _updateCumulativeSum() internal returns (uint256 _newCumulativeSum) {
        uint256 _totalPool = totalPoolStaked;
        uint256 _lastUpdate = lastUpdate;
        _lastUpdate = _lastUpdate == 0 ? block.number : _lastUpdate;

        if (_totalPool > 0) {
            _newCumulativeSum = _getNewCumulativeSum(
                rewardPerBlock,
                _totalPool,
                cumulativeSum,
                block.number - _lastUpdate
            );

            cumulativeSum = _newCumulativeSum;
        }

        lastUpdate = block.number;
    }

    function _getNewCumulativeSum(
        uint256 _rewardPerBlock,
        uint256 _totalPool,
        uint256 _prevAP,
        uint256 _blocksDelta
    ) internal pure returns (uint256) {
        uint256 _newPrice = (_rewardPerBlock * DECIMAL) / _totalPool;
        return _blocksDelta * _newPrice + _prevAP;
    }

    function _updateUserRewards(uint256 _newCumulativeSum) internal {
        UserInfo storage userInfo = userInfos[msg.sender];

        uint256 _currentUserStakedAmount = userInfo.stakedAmount;

        if (_currentUserStakedAmount > 0) {
            userInfo.aggregatedReward +=
                ((_newCumulativeSum - userInfo.lastCumulativeSum) * _currentUserStakedAmount) /
                DECIMAL;
        }

        userInfo.lastCumulativeSum = _newCumulativeSum;
    }

    function getLatestUserRewards(address _userAddr) public view returns (uint256) {
        uint256 _totalPool = totalPoolStaked;
        uint256 _lastUpdate = lastUpdate;

        uint256 _newCumulativeSum;

        _lastUpdate = _lastUpdate == 0 ? block.number : _lastUpdate;

        if (_totalPool > 0) {
            _newCumulativeSum = _getNewCumulativeSum(
                rewardPerBlock,
                _totalPool,
                cumulativeSum,
                block.number - _lastUpdate
            );
        }

        UserInfo memory userInfo = userInfos[_userAddr];

        uint256 _currentUserStakedAmount = userInfo.stakedAmount;
        uint256 _agregatedRewards = userInfo.aggregatedReward;

        if (_currentUserStakedAmount > 0) {
            _agregatedRewards =
                _agregatedRewards +
                ((_newCumulativeSum - userInfo.lastCumulativeSum) * _currentUserStakedAmount) /
                DECIMAL;
        }

        return _agregatedRewards;
    }

    function getLatestUserRewardsAfterSlashing(address _userAddr) external view returns (uint256) {
        return _applySlashing(getLatestUserRewards(_userAddr));
    }

    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(address(_token) != address(stakeToken), "Not possible to withdraw stake token");
        _token.transfer(_to, _amount);
    }
}
