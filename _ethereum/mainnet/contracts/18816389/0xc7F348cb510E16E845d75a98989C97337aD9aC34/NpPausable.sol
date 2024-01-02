// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./PausableUpgradeable.sol";

contract NpPausable is PausableUpgradeable {
    function _setPause(bool _paused) internal {
        bool current = paused();
        if (_paused && !current) {
            _pause();
        } else if (!_paused && current) {
            _unpause();
        }
    }
}
