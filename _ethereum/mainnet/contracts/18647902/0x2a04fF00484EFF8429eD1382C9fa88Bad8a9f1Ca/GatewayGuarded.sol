// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IGatewayGuarded.sol";

/**
 * The management interface exposed to gateway.
 */
abstract contract GatewayGuarded is IGatewayGuarded {
    
    address public gateway;

    modifier onlyGateway() {
        _checkGateway();
        _;
    }

    constructor(address _gateway) {
        gateway = _gateway;
    }

    /**
     * @dev Throws if the sender is not the gateway contract.
     */
    function _checkGateway() internal view virtual {
        require(gateway == msg.sender, "GatewayGuarded: caller is not the gateway");
    }

    /**
     * @inheritdoc IGatewayGuarded
     */
    function setGateway(address _gateway) external override onlyGateway {
        gateway = _gateway;
    }

}
