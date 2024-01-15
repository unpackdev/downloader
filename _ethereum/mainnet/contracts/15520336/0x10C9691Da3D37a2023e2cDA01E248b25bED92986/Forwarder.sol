// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Initializable.sol";
import "./MinimalForwarderUpgradeable.sol";

contract Forwarder is Initializable, MinimalForwarderUpgradeable {
    function initialize() public initializer {
        __MinimalForwarder_init();
    }
}
