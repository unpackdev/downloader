// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./FixedTokenTimelockUpgradeable.sol";

contract FixedQuadraticTokenTimelockUpgradeable is Initializable, FixedTokenTimelockUpgradeable {

    function initialize(
        address _beneficiary,
        uint256 _duration,
        address _lockedToken,
        uint256 _cliffDuration,
        address _clawbackAdmin,
        uint256 _lockedAmount,
        uint256 _startTime
    ) external initializer {
        __FixedTokenTimelock_init(
            _beneficiary, 
            _duration, 
            _lockedToken, 
            _cliffDuration,
            _clawbackAdmin,
            _lockedAmount
        );

        if (_startTime != 0) {
            startTime = _startTime;
        }
    }

    function _proportionAvailable(
        uint256 initialBalance,
        uint256 elapsed,
        uint256 duration
    ) internal pure override returns (uint256) {
        uint year = 31536000;
        if (elapsed <= year) return elapsed / year * initialBalance / 10; // 10% of the initial balance
        else if (elapsed <= 2 * year) return elapsed / (2 * year) * initialBalance / 4; // 25%
        else if (elapsed <= 3 * year) return elapsed / (3 * year) * initialBalance * 45 / 100; // 45%
        else if (elapsed <= 4 * year) return elapsed / (4 * year) * initialBalance * 7 / 10; // 70 %
        else if (elapsed < 5 * year) return elapsed / (5 * year) * initialBalance;
        else return initialBalance;
    }
}
