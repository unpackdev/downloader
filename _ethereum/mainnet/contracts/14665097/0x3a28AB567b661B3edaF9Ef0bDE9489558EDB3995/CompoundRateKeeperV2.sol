// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ICompoundRateKeeperV2.sol";

import "./console.sol";

/// @notice CompoundRateKeeperV2 contract.
contract CompoundRateKeeperV2 is ICompoundRateKeeperV2, Ownable {
    uint256 public currentRate;
    uint256 public annualPercent;

    uint64 public capitalizationPeriod;
    uint64 public lastUpdate;

    bool public hasMaxRateReached;

    constructor() {
        capitalizationPeriod = 31536000;
        lastUpdate = uint64(block.timestamp);

        annualPercent = _getDecimals();
        currentRate = _getDecimals();
    }

    /// @notice Set new capitalization period
    /// @param _capitalizationPeriod Seconds
    function setCapitalizationPeriod(uint32 _capitalizationPeriod) external override onlyOwner {
        require(_capitalizationPeriod > 0, "CompoundRateKeeperV2: capitalization period can't be a zero.");

        currentRate = __getPotentialCompoundRate(uint64(block.timestamp));
        capitalizationPeriod = _capitalizationPeriod;

        lastUpdate = uint64(block.timestamp);

        emit CapitalizationPeriodChanged(_capitalizationPeriod);
    }

    /// @notice Call this function only when getCompoundRate() or getPotentialCompoundRate() throw error
    /// @notice Update hasMaxRateReached switcher to True
    function emergencyUpdateCompoundRate() external override {
        try this.getCompoundRate() returns (uint256 _rate) {
            if (_rate == __getMaxRate()) hasMaxRateReached = true;
        } catch {
            hasMaxRateReached = true;
        }
    }

    /// @notice Calculate compound rate for this moment.
    function getCompoundRate() public view override returns (uint256) {
        return __getPotentialCompoundRate(uint64(block.timestamp));
    }

    /// @notice Calculate compound rate at a particular time.
    /// @param _timestamp Seconds
    function getPotentialCompoundRate(uint64 _timestamp) public view override returns (uint256) {
        return __getPotentialCompoundRate(_timestamp);
    }

    /// @notice Set new annual percent
    /// @param _annualPercent = 1*10^27 (0% per period), 1.1*10^27 (10% per period), 2*10^27 (100% per period)
    function _setAnnualPercent(uint256 _annualPercent) internal {
        require(!hasMaxRateReached, "CompoundRateKeeperV2: the rate maximum has been reached.");
        require(_annualPercent >= _getDecimals(), "CompoundRateKeeperV2: annual percent can't be less then 1.");

        currentRate = __getPotentialCompoundRate(uint64(block.timestamp));
        annualPercent = _annualPercent;

        lastUpdate = uint64(block.timestamp);

        emit AnnualPercentChanged(_annualPercent);
    }

    /// @dev Decimals for number.
    function _getDecimals() internal pure returns (uint256) {
        return 10**27;
    }

    /// @dev Main contract logic, calculate actual compound rate
    /// @dev If rate bigger than __getMaxRate(), return __getMaxRate()
    /// @dev Return actual rate, max rate if actual bigger than max, and throw error when values to big
    /// @dev If function return error, call emergencyUpdateCompoundRate()
    function __getPotentialCompoundRate(uint64 _timestamp) private view returns (uint256) {
        uint256 _maxRate = __getMaxRate();
        if (hasMaxRateReached) return _maxRate;

        uint64 _lastUpdate = lastUpdate;
        // Revert is made to avoid incorrect calculations at the front
        if (_timestamp == _lastUpdate) {
            return currentRate;
        } else if (_timestamp < _lastUpdate) {
            revert("CompoundRateKeeperV2: timestamp can't be less then last update.");
        }

        uint64 _secondsPassed = _timestamp - _lastUpdate;

        uint64 _capitalizationPeriod = capitalizationPeriod;
        uint64 _capitalizationPeriodsNum = _secondsPassed / _capitalizationPeriod;
        uint64 _secondsLeft = _secondsPassed % _capitalizationPeriod;

        uint256 _annualPercent = annualPercent;
        uint256 _rate = currentRate;

        if (_capitalizationPeriodsNum != 0) {
            uint256 _capitalizationPeriodRate = __pow(_annualPercent, _capitalizationPeriodsNum, _getDecimals());
            _rate = (_rate * _capitalizationPeriodRate) / _getDecimals();
        }

        if (_secondsLeft > 0) {
            uint256 _rateLeft = _getDecimals() +
                ((_annualPercent - _getDecimals()) * _secondsLeft) /
                _capitalizationPeriod;

            _rate = (_rate * _rateLeft) / _getDecimals();
        }

        return _rate > _maxRate ? _maxRate : _rate;
    }

    /// @dev Max accessible compound rate.
    function __getMaxRate() private pure returns (uint256) {
        return type(uint128).max * _getDecimals();
    }

    /// @dev github.com/makerdao/dss implementation of exponentiation by squaring
    function __pow(
        uint256 _num,
        uint256 _exponent,
        uint256 _base
    ) private pure returns (uint256 _res) {
        assembly {
            function power(x, n, b) -> z {
                switch x
                case 0 {
                    switch n
                    case 0 {
                        z := b
                    }
                    default {
                        z := 0
                    }
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    }
                    default {
                        z := x
                    }

                    let half := div(b, 2)
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }

                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }

                            z := div(zxRound, b)
                        }
                    }
                }
            }

            _res := power(_num, _exponent, _base)
        }
    }
}
