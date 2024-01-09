// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./IERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./SafeCast.sol";

import "./ILockTOSDividend.sol";
import "./ILockTOS.sol";
import "./LibLockTOSDividend.sol";

import "./AccessibleCommon.sol";
import "./LockTOSDividendStorage.sol";

contract LockTOSDividend is
    LockTOSDividendStorage,
    AccessibleCommon,
    ILockTOSDividend
{
    event Claim(address indexed token, uint256 amount, uint256 timestamp);
    event Distribute(address indexed token, uint256 amount);
    event Redistribute(address indexed token, uint256 oldEpoch, uint256 newEpoch);

    using SafeMath for uint256;
    using SafeCast for uint256;

    /// @dev Check if a function is used or not
    modifier ifFree {
        require(free == 1, "LockId is already in use");
        free = 0;
        _;
        free = 1;
    }

    /// @inheritdoc ILockTOSDividend
    function claim(address _token) public override {
        uint256 timestamp = block.timestamp - epochUnit;
        _claimUpTo(_token, timestamp);
    }

    /// @inheritdoc ILockTOSDividend
    function claimBatch(address[] calldata _tokens) external override {
        for (uint i = 0; i < _tokens.length; ++i) {
            claim(_tokens[i]);
        }
    }

    /// @inheritdoc ILockTOSDividend
    function claimUpTo(address _token, uint256 _timestamp) external override {
        uint256 timestamp = Math.min(_timestamp, block.timestamp - epochUnit);
        _claimUpTo(_token, timestamp);
    }
    
    function redistribute(address _token, uint256 _weeklyEpoch)
        external
        // override
    {
        require(_weeklyEpoch < getCurrentWeeklyEpoch());
        uint256 timestamp = genesis.add(_weeklyEpoch.mul(epochUnit)).add(epochUnit);

        require(
            ILockTOS(lockTOS).totalSupplyAt(timestamp) == 0,
            "Locked Token exists for that epoch"
        );

        uint256 newEpoch = _weeklyEpoch.add(1);
        uint256 newTimestamp = timestamp.add(epochUnit);
        while (newTimestamp <= block.timestamp) {
            if (ILockTOS(lockTOS).totalSupplyAt(newTimestamp) > 0) {
                break;
            }
            newTimestamp = newTimestamp.add(epochUnit);
            newEpoch = newEpoch.add(1);
        }
        require(
            newTimestamp <= block.timestamp,
            "Cannot find epoch to redistribute"
        );

        LibLockTOSDividend.Distribution storage distr = distributions[_token];
        distr.tokensPerWeek[newEpoch] = distr.tokensPerWeek[newEpoch].add(
            distr.tokensPerWeek[_weeklyEpoch]
        );
        distr.tokensPerWeek[_weeklyEpoch] = 0;

        emit Redistribute(_token, _weeklyEpoch, newEpoch);
    }

    /// @inheritdoc ILockTOSDividend
    function distribute(address _token, uint256 _amount)
        external
        override
        ifFree
    {
        uint256 weeklyEpoch = getCurrentWeeklyEpoch();
        LibLockTOSDividend.Distribution storage distr = distributions[_token];
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        if (distr.exists == false) {
            distributedTokens.push(_token);
        }

        uint256 newBalance = IERC20(_token).balanceOf(address(this));
        uint256 increment = newBalance.sub(distr.lastBalance);
        distr.exists = true;
        distr.lastBalance = newBalance;
        distr.totalDistribution = distr.totalDistribution.add(increment);
        distr.tokensPerWeek[weeklyEpoch] = distr.tokensPerWeek[weeklyEpoch].add(increment);
        emit Distribute(_token, _amount);
    }

    /// @inheritdoc ILockTOSDividend
    function getWeeklyEpoch(uint256 _timestamp)
        public
        view
        override
        returns (uint256)
    {
        return _timestamp > genesis ? (_timestamp.sub(genesis)).div(epochUnit) : 0;
    }

    function epochToTimestamp(uint256 _epoch)
        public
        view
        // override
        returns (uint256)
    {
        return genesis.add(_epoch.mul(epochUnit)).add(epochUnit);
    }

    /// @inheritdoc ILockTOSDividend
    function tokensPerWeekAt(address _token, uint256 _timestamp)
        external
        view
        override
        returns (uint256)
    {
        uint256 weeklyEpoch = getWeeklyEpoch(_timestamp);
        return distributions[_token].tokensPerWeek[weeklyEpoch];
    }

    /// @inheritdoc ILockTOSDividend
    function claimStartWeeklyEpoch(address _token, uint256 _lockId)
        external
        view
        override
        returns (uint256)
    {
        return distributions[_token].claimStartWeeklyEpoch[_lockId];
    }

    /// @inheritdoc ILockTOSDividend
    function getCurrentWeeklyEpoch() public view override returns (uint256) {
        return getWeeklyEpoch(block.timestamp);
    }

    /// @inheritdoc ILockTOSDividend
    function getCurrentWeeklyEpochTimestamp() public view override returns (uint256) {
        uint256 weeklyEpoch = getCurrentWeeklyEpoch();
        uint256 timestamp = genesis.add(weeklyEpoch.mul(epochUnit)) + epochUnit;
        return timestamp;
    }
    
    /// @inheritdoc ILockTOSDividend
    function ifDistributionPossible() public view override returns (bool) {
        uint256 timestamp = getCurrentWeeklyEpochTimestamp();
        return ILockTOS(lockTOS).totalSupplyAt(timestamp) > 0;
    }

    /// @inheritdoc ILockTOSDividend
    function claimable(address _account, address _token) public view override returns (uint256) {
        return claimableForPeriod(_account, _token, genesis, block.timestamp);
    }

    /// @inheritdoc ILockTOSDividend
    function getAvailableClaims(address _account) public view override returns (address[] memory claimableTokens, uint256[] memory claimableAmounts) {
        uint256[] memory amounts = new uint256[](distributedTokens.length);
        uint256 claimableCount = 0;
        for (uint256 i = 0; i < distributedTokens.length; ++i) {
            amounts[i] = claimable(_account, distributedTokens[i]);
            if (amounts[i] > 0) {
                claimableCount += 1;
            }
        }

        claimableAmounts = new uint256[](claimableCount);
        claimableTokens = new address[](claimableCount);
        uint256 j = 0;
        for (uint256 i = 0; i < distributedTokens.length; ++i) {
            if (amounts[i] > 0) {
                claimableAmounts[j] = amounts[i];
                claimableTokens[j] = distributedTokens[i];
                j++;
            }
        }
    }

    /// @inheritdoc ILockTOSDividend
    function claimableForPeriod(
        address _account,
        address _token,
        uint256 _timeStart,
        uint256 _timeEnd
    ) public view override returns (uint256) {
        uint256 epochStart = getWeeklyEpoch(_timeStart);
        uint256 timestampEnd = Math.min(_timeEnd, block.timestamp - epochUnit);
        uint256 epochEnd = getWeeklyEpoch(timestampEnd);
        if (epochEnd == 0) {
            return 0;
        }

        uint256[] memory userLocks = ILockTOS(lockTOS).locksOf(_account);
        uint256 amountToClaim = 0;
        LibLockTOSDividend.Distribution storage distr = distributions[_token];
        for (uint256 i = 0; i < userLocks.length; ++i) {
            uint256 lockId = userLocks[i];
            amountToClaim += _calculateClaim(
                distr,
                lockId,
                Math.max(epochStart, distr.claimStartWeeklyEpoch[lockId]),
                epochEnd
            );
        }
        return amountToClaim;
    }

    /// @dev Claim rewards
    function _claimUpTo(address _token, uint256 _timestamp) internal ifFree {
        uint256 weeklyEpoch = getWeeklyEpoch(_timestamp);
        uint256[] memory userLocks = ILockTOS(lockTOS).locksOf(msg.sender);
        uint256 amountToClaim = 0;
        for (uint256 i = 0; i < userLocks.length; ++i) {
            amountToClaim = amountToClaim.add(
                _recordClaim(_token, userLocks[i], weeklyEpoch)
            );
        }
        require(amountToClaim > 0, "Amount to be claimed is zero");
        IERC20(_token).transfer(msg.sender, amountToClaim);
        emit Claim(_token, amountToClaim, _timestamp);
    }

    /// @dev Record claim
    function _recordClaim(
        address _token,
        uint256 _lockId,
        uint256 _weeklyEpoch
    ) internal returns (uint256 amountToClaim) {
        LibLockTOSDividend.Distribution storage distr = distributions[_token];
        amountToClaim = _calculateClaim(
            distr,
            _lockId,
            distr.claimStartWeeklyEpoch[_lockId],
            _weeklyEpoch
        );

        distr.claimStartWeeklyEpoch[_lockId] = _weeklyEpoch.add(1);
        distr.lastBalance = distr.lastBalance.sub(amountToClaim);
        return amountToClaim;
    }

    /// @dev Amount claimable
    function _calculateClaim(
        LibLockTOSDividend.Distribution storage _distr,
        uint256 _lockId,
        uint256 _startEpoch,
        uint256 _endEpoch
    ) internal view returns (uint256) {
        (uint256 start, uint256 end,) = ILockTOS(lockTOS).locksInfo(_lockId);

        uint256 epochIterator = Math.max(_startEpoch, getWeeklyEpoch(start));
        uint256 epochLimit = Math.min(_endEpoch, getWeeklyEpoch(end));

        uint256 accumulated = 0;
        while (epochIterator <= epochLimit) {
            accumulated = accumulated.add(
                _calculateClaimPerEpoch( 
                    _lockId,
                    epochIterator,
                    _distr.tokensPerWeek[epochIterator]
                )
            );
            epochIterator = epochIterator.add(1);
        }
        return accumulated;
    }

    /// @dev Calculates claim portion
    function _calculateClaimPerEpoch(
        uint256 _lockId,
        uint256 _weeklyEpoch,
        uint256 _tokensPerWeek
    ) internal view returns (uint256) {
        uint256 timestamp =
            genesis.add(_weeklyEpoch.mul(epochUnit)) + epochUnit;
        uint256 balance = ILockTOS(lockTOS).balanceOfLockAt(_lockId, timestamp);
        uint256 supply = ILockTOS(lockTOS).totalSupplyAt(timestamp);
        if (balance == 0 || supply == 0) {
            return 0;
        }
        return _tokensPerWeek.mul(balance).div(supply);
    }
}
