// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./GelatoRelay.sol";

abstract contract GelatoRelayBase {
    modifier onlyGelatoRelay() {
        require(_isGelatoRelay(msg.sender), "onlyGelatoRelay");
        _;
    }

    function _isGelatoRelay(address _forwarder) internal view returns (bool) {
        // Use another address on zkSync
        if (block.chainid == 324 || block.chainid == 280) {
            return _forwarder == GELATO_RELAY_ZKSYNC;
        }
        return _forwarder == GELATO_RELAY;
    }
}
