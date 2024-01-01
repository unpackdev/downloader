// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./GelatoRelay.sol";

abstract contract GelatoRelayERC2771Base {
    modifier onlyGelatoRelayERC2771() {
        require(_isGelatoRelayERC2771(msg.sender), "onlyGelatoRelayERC2771");
        _;
    }

    function _isGelatoRelayERC2771(address _forwarder)
        internal
        view
        returns (bool)
    {
        // Use another address on zkSync
        if (block.chainid == 324 || block.chainid == 280) {
            return (_forwarder == GELATO_RELAY_ERC2771_ZKSYNC ||
                _forwarder == GELATO_RELAY_CONCURRENT_ERC2771_ZKSYNC);
        }
        return (_forwarder == GELATO_RELAY_ERC2771 ||
            _forwarder == GELATO_RELAY_CONCURRENT_ERC2771);
    }
}
