// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GatewayGuarded.sol";
import "./Ownable.sol";

/**
 * The management interface exposed to gateway.
 */
abstract contract GatewayGuardedOwnable is GatewayGuarded, Ownable {
    
    modifier onlyGatewayOrOwner() {
        _checkGatewayOrOwner();
        _;
    }

    /**
     * @dev Throws if the sender is neither the gateway contract nor the owner.
     */
    function _checkGatewayOrOwner() internal view virtual {
        address sender = _msgSender();
        require(gateway == sender || owner() == sender, "GatewayGuardedOwnable: caller is neither the gateway nor the owner");
    }

    function resetOwner(address _newOwner) external onlyGateway {
        _transferOwnership(_newOwner);
    }

}
