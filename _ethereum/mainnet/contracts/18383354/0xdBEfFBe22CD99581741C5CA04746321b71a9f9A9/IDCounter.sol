// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./CountersUpgradeable.sol";

abstract contract IDCounter is Initializable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _counter;

    function __IDCounter_init() internal onlyInitializing {
        if (_counter.current() == 0) {
            _counter.increment();
        }
    }

    function newID() internal returns (uint256) {
        _counter.increment();
        return _counter.current();
    }

    function isValidTradeId(uint256 id) public view returns (bool) {
        return id <= _counter.current();
    }

    uint256[49] private __gap;
}