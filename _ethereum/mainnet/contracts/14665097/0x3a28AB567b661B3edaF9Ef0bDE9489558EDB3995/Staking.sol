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

    struct APY {
        uint256 currentIndex;
        uint256[] amounts;
        uint256[] annualPercents;
    }

    /// @notice Staker address to staker info.
    mapping(address => Stake) public addressToStake;
    /// @notice Stake start timestamp.
    uint64 public startTimestamp;
    /// @notice Stake end timestamp.
    uint64 public endTimestamp;
    /// @notice Period when address can't withdraw after stake.
    uint64 public lockPeriod;

    APY private __apy;

    uint256 private __aggregatedAmount;
    uint256 private __aggregatedNormalizedAmount;

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

    /// @notice Set APY and amount of tokens for APY.
    /// @param _amounts Tokens. Wei
    /// @param _annualPercents Percents, decimals. Should be longer then `_amounts` by one
    function setAPY(uint256[] calldata _amounts, uint256[] calldata _annualPercents) external onlyOwner {
        require(_amounts.length + 1 == _annualPercents.length, "Staking: invalid array length.");

        for (uint256 _i; _i < _amounts.length; _i++) {
            if (_i > 0) {
                require(_amounts[_i] > _amounts[_i - 1], "Staking: invalid amount value.");
                require(_annualPercents[_i] >= _getDecimals(), "Staking: annual percent can't be less then 1.");
            }
        }

        __apy.amounts = _amounts;
        __apy.annualPercents = _annualPercents;

        // Recalculate percent and definitely update actual annual percent
        // Actual when percent changed but nol limits have not changed
        uint256 _newIndex = __recalculateAnnualPercent(__aggregatedAmount);
        _setAnnualPercent(__apy.annualPercents[_newIndex]);
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
            _newAmount = __getDenormalizedAmount(_normalizedAmount, _compoundRate) + _amount;
        } else {
            _newAmount = _amount;
        }
        _newNormalizedAmount = (_newAmount * _getDecimals()) / _compoundRate;

        uint256 _newAggregatedAmount = __aggregatedAmount + _amount;

        __aggregatedAmount = _newAggregatedAmount;
        __aggregatedNormalizedAmount = __aggregatedNormalizedAmount + _newNormalizedAmount - _normalizedAmount;

        addressToStake[msg.sender].amount += _amount;
        addressToStake[msg.sender].normalizedAmount = _newNormalizedAmount;
        addressToStake[msg.sender].lastUpdate = uint64(block.timestamp);

        __recalculateAnnualPercent(_newAggregatedAmount);

        return true;
    }

    /// @notice Withdraw tokens from stake.
    /// @param _withdrawAmount Tokens amount to withdraw
    function withdraw(uint256 _withdrawAmount) external override returns (bool) {
        require(_withdrawAmount > 0, "Staking: the amount cannot be a zero.");

        uint256 _compoundRate = getCompoundRate();
        uint256 _stakedAmount = addressToStake[msg.sender].amount;
        uint256 _normalizedAmount = addressToStake[msg.sender].normalizedAmount;
        uint256 _availableAmount = __getDenormalizedAmount(_normalizedAmount, _compoundRate);
        uint256 _rewardAmount = _availableAmount - _stakedAmount;

        require(_availableAmount > 0, "Staking: available amount is zero.");

        if (addressToStake[msg.sender].lastUpdate + lockPeriod >= block.timestamp) {
            _availableAmount = _stakedAmount;
            _withdrawAmount = _stakedAmount;
            _rewardAmount = 0;
        }

        if (_availableAmount < _withdrawAmount) _withdrawAmount = _availableAmount;

        uint256 _newRealAmount = _availableAmount - _withdrawAmount;
        uint256 _newStakedAmount = _withdrawAmount > _rewardAmount ? _newRealAmount : _stakedAmount;
        uint256 _newNormalizedAmount = (_newRealAmount * _getDecimals()) / _compoundRate;

        uint256 _newAggregatedAmount = __aggregatedAmount + _newStakedAmount - _stakedAmount;

        __aggregatedAmount = _newAggregatedAmount;
        __aggregatedNormalizedAmount = __aggregatedNormalizedAmount + _newNormalizedAmount - _normalizedAmount;

        addressToStake[msg.sender].amount = _newStakedAmount;
        addressToStake[msg.sender].normalizedAmount = _newNormalizedAmount;

        token.transfer(msg.sender, _withdrawAmount);

        __recalculateAnnualPercent(_newAggregatedAmount);

        return true;
    }

    /// @notice Return amount of tokens + percents at this moment.
    /// @param _address Staker address
    function getDenormalizedAmount(address _address) external view override returns (uint256) {
        return __getDenormalizedAmount(addressToStake[_address].normalizedAmount, getCompoundRate());
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
        return (__aggregatedNormalizedAmount * getCompoundRate()) / _getDecimals() - __aggregatedAmount;
    }

    /// @notice Return aggregated staked amount (without percents).
    function getAggregatedAmount() external view override returns (uint256) {
        return __aggregatedAmount;
    }

    /// @notice Return aggregated normalized amount.
    function getAggregatedNormalizedAmount() external view override returns (uint256) {
        return __aggregatedNormalizedAmount;
    }

    /// @notice Return coefficient in decimals. If coefficient more than 1, all holders will be able to receive awards.
    function monitorSecurityMargin() external view override onlyOwner returns (uint256) {
        uint256 _toWithdraw = (__aggregatedNormalizedAmount * getCompoundRate()) / _getDecimals();

        if (_toWithdraw == 0) return _getDecimals();
        return (token.balanceOf(address(this)) * _getDecimals()) / _toWithdraw;
    }

    function getAPYInfo() external view returns (uint256, uint256[] memory, uint256[] memory) {
        return (__apy.annualPercents[__apy.currentIndex], __apy.annualPercents, __apy.amounts);
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
                (__aggregatedNormalizedAmount * getCompoundRate()) /
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

    function recalculateAnnualPercent() external {
        __recalculateAnnualPercent(__aggregatedAmount);
    }

    /// @dev Calculate denormalized amount.
    function __getDenormalizedAmount(uint256 _normalizedAmount, uint256 _compoundRate) private pure returns (uint256) {
        return (_normalizedAmount * _compoundRate) / _getDecimals();
    }

    /// @dev Update annual percent depending on `_aggregatedAmount`.
    function __recalculateAnnualPercent(uint256 _aggregatedAmount) private returns (uint256) {
        uint256 _amountLength = __apy.amounts.length;

        uint256 _currentIndex = __apy.currentIndex;
        // Max limit for current index
        uint256 _maxIndexAmount = _currentIndex > _amountLength - 1 ? type(uint256).max :  __apy.amounts[_currentIndex];
        // Min limit for current index
        uint256 _minIndexAmount =  _currentIndex > 0 ? __apy.amounts[_currentIndex - 1] : 0;

        if (_minIndexAmount < _aggregatedAmount && _aggregatedAmount <= _maxIndexAmount) return _currentIndex;

        uint256 _newIndex;
        // Looking for the closest to the current index
        if (_aggregatedAmount <= _minIndexAmount) {
            if (_currentIndex == 0) {
                _newIndex = 0;
            } else {
                for (uint256 _i = _currentIndex - 1; _i >= 0; _i--) {
                    if (_aggregatedAmount <= __apy.amounts[_i]) _newIndex = _i;
                    if (_aggregatedAmount > __apy.amounts[_i] || _i == 0) break;
                }
            }
        } else {
            for (uint256 _i = _currentIndex + 1; _i > 0; _i++) {
                if (_i == _amountLength) {
                    _newIndex = _amountLength;
                    break;
                }
                if (_aggregatedAmount <= __apy.amounts[_i]) {
                    _newIndex = _i;
                    break;
                }
            }
        }

        // If index change, update him and annual percent
        if (_currentIndex != _newIndex) {
            __apy.currentIndex = _newIndex;
            if (!hasMaxRateReached) _setAnnualPercent(__apy.annualPercents[_newIndex]);
        }

        return _newIndex;
    }
}
