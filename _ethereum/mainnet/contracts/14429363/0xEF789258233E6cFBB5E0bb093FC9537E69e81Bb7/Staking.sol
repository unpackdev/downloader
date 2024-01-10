// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./CompoundRateKeeperV2.sol";
import "./IStaking.sol";

contract Staking is IStaking, CompoundRateKeeperV2 {
    /// @notice Staking token contract address.
    IERC20 public token;

    struct Stake {
        uint256 amount;
        uint256 normalizedAmount;
        uint64 lastUpdate;
    }

    /// @notice Staker address to staker info.
    mapping(address => Stake) public addressToStake;
    /// @notice Stake start timestamp.
    uint64 public startTimestamp;
    /// @notice Stake end timestamp.
    uint64 public endTimestamp;
    /// @notice Period when address can't withdraw after stake.
    uint64 public lockPeriod;

    uint256 private aggregatedAmount;
    uint256 private aggregatedNormalizedAmount;

    constructor(
        IERC20 _token,
        uint64 _startTimestamp,
        uint64 _endTimestamp,
        uint64 _lockPeriod
    ) {
        require(_endTimestamp > block.timestamp, "Staking: incorrect end timestamps.");
        require(_endTimestamp > _startTimestamp, "Staking: incorrect start timestamps.");

        token = _token;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        lockPeriod = _lockPeriod;
    }

    /// @notice Update lock period.
    /// @param _lockPeriod Timestamp
    function setLockPeriod(uint64 _lockPeriod) external override onlyOwner {
        lockPeriod = _lockPeriod;
    }

    /// @notice Stake tokens to contract.
    /// @param _amount Stake amount
    function stake(uint256 _amount) external override returns (bool) {
        require(_amount > 0, "Staking: the amount cannot be a zero.");
        require(startTimestamp <= block.timestamp, "Staking: staking is not started.");
        require(endTimestamp >= block.timestamp, "Staking: staking is ended.");

        token.transferFrom(msg.sender, address(this), _amount);

        uint256 _compoundRate = getCompoundRate();
        uint256 _normalizedAmount = addressToStake[msg.sender].normalizedAmount;
        uint256 _newAmount;
        uint256 _newNormalizedAmount;

        if (_normalizedAmount > 0) {
            _newAmount = _getDenormalizedAmount(_normalizedAmount, _compoundRate) + _amount;
        } else {
            _newAmount = _amount;
        }
        _newNormalizedAmount = (_newAmount * _getDecimals()) / _compoundRate;

        aggregatedAmount = aggregatedAmount - addressToStake[msg.sender].amount + _newAmount;
        aggregatedNormalizedAmount = aggregatedNormalizedAmount - _normalizedAmount + _newNormalizedAmount;

        addressToStake[msg.sender].amount = _newAmount;
        addressToStake[msg.sender].normalizedAmount = _newNormalizedAmount;
        addressToStake[msg.sender].lastUpdate = uint64(block.timestamp);

        return true;
    }

    /// @notice Withdraw tokens from stake.
    /// @param _withdrawAmount Tokens amount to withdraw
    function withdraw(uint256 _withdrawAmount) external override returns (bool) {
        require(_withdrawAmount > 0, "Staking: the amount cannot be a zero.");

        uint256 _compoundRate = getCompoundRate();
        uint256 _normalizedAmount = addressToStake[msg.sender].normalizedAmount;
        uint256 _availableAmount = _getDenormalizedAmount(_normalizedAmount, _compoundRate);

        require(_availableAmount > 0, "Staking: available amount is zero.");
        require(
            addressToStake[msg.sender].lastUpdate + lockPeriod < block.timestamp,
            "Staking: wait for the lockout period to expire."
        );

        if (_availableAmount < _withdrawAmount) _withdrawAmount = _availableAmount;

        uint256 _newAmount = _availableAmount - _withdrawAmount;
        uint256 _newNormalizedAmount = (_newAmount * _getDecimals()) / _compoundRate;

        aggregatedAmount = aggregatedAmount - addressToStake[msg.sender].amount + _newAmount;
        aggregatedNormalizedAmount = aggregatedNormalizedAmount - _normalizedAmount + _newNormalizedAmount;

        addressToStake[msg.sender].amount = _newAmount;
        addressToStake[msg.sender].normalizedAmount = _newNormalizedAmount;

        token.transfer(msg.sender, _withdrawAmount);

        return true;
    }

    /// @notice Return amount of tokens + percents at this moment.
    /// @param _address Staker address
    function getDenormalizedAmount(address _address) external view override returns (uint256) {
        return _getDenormalizedAmount(addressToStake[_address].normalizedAmount, getCompoundRate());
    }

    /// @notice Return amount of tokens + percents at given timestamp.
    /// @param _address Staker address
    /// @param _timestamp Given timestamp (seconds)
    function getPotentialAmount(address _address, uint64 _timestamp) external view override returns (uint256) {
        return (addressToStake[_address].normalizedAmount * getPotentialCompoundRate(_timestamp)) / _getDecimals();
    }

    /// @notice Transfer tokens to contract as reward.
    /// @param _amount Token amount
    function supplyRewardPool(uint256 _amount) external override returns (bool) {
        return token.transferFrom(msg.sender, address(this), _amount);
    }

    /// @notice Return total reward amount.
    function getTotalRewardAmount() external view override returns (uint256) {
        return (aggregatedNormalizedAmount * getCompoundRate()) / _getDecimals() - aggregatedAmount;
    }

    /// @notice Return aggregated staked amount (without percents).
    function getAggregatedAmount() external view override returns (uint256) {
        return aggregatedAmount;
    }

    /// @notice Return aggregated normalized amount.
    function getAggregatedNormalizedAmount() external view override onlyOwner returns (uint256) {
        return aggregatedNormalizedAmount;
    }

    /// @notice Return coefficient in decimals. If coefficient more than 1, all holders will be able to receive awards.
    function monitorSecurityMargin() external view override onlyOwner returns (uint256) {
        uint256 _toWithdraw = (aggregatedNormalizedAmount * getCompoundRate()) / _getDecimals();

        if (_toWithdraw == 0) return _getDecimals();
        return (token.balanceOf(address(this)) * _getDecimals()) / _toWithdraw;
    }

    /// @notice Transfer stuck ERC20 tokens.
    /// @param _token Token address
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner returns (bool) {
        if (address(token) == address(_token)) {
            uint256 _availableAmount = token.balanceOf(address(this)) -
                (aggregatedNormalizedAmount * getCompoundRate()) /
                _getDecimals();
            _amount = _availableAmount < _amount ? _availableAmount : _amount;
        }

        return _token.transfer(_to, _amount);
    }

    /// @notice Transfer stuck native tokens.
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function transferStuckNativeToken(address payable _to, uint256 _amount) external override onlyOwner {
        _to.transfer(_amount);
    }

    /// @dev Calculate denormalized amount.
    function _getDenormalizedAmount(uint256 _normalizedAmount, uint256 _compoundRate) private pure returns (uint256) {
        return (_normalizedAmount * _compoundRate) / _getDecimals();
    }
}
