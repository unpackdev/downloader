// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IOperatorFilterRegistry.sol";

/**
 * @dev copied from operator-filter-registry/src/upgradeable/OperatorFiltererUpgradeable.sol
 * @dev some of the control flow was removed to remove unnecessary branches
 */
contract DiamondOperatorFilter {
    IOperatorFilterRegistry constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    /// @dev The upgradeable initialize function that should be called when the contract is being upgraded.
    function __OperatorFilterer_init(address subscriptionOrRegistrantToCopy) internal {
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isRegistered(address(this))) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            }
        }
    }
}
