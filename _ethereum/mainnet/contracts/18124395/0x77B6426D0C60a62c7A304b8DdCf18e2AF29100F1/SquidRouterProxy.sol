// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./InitProxy.sol";

contract SquidRouterProxy is InitProxy {
    function contractId() internal pure override returns (bytes32 id) {
        id = keccak256("squid-router");
    }
}
