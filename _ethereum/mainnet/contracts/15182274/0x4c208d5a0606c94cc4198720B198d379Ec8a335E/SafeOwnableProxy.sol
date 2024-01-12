// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ISafeOwnable.sol";
import "./SafeOwnableController.sol";
import "./OwnableProxy.sol";

/**
 * @title ERC173 safe ownership access control implementation
 * @dev Note: Upgradable implementation
 */
abstract contract SafeOwnableProxy is ISafeOwnable, OwnableProxy, SafeOwnableController {
    /**
     * @inheritdoc ISafeOwnable
     */
    function nomineeOwner() external virtual upgradable returns (address) {
        return nomineeOwner_();
    }

    /**
     * @inheritdoc ISafeOwnable
     */
    function acceptOwnership() external virtual upgradable onlyNomineeOwner {
        acceptOwnership_();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address newOwner)
        external
        virtual
        override(IERC173, OwnableProxy)
        upgradable
        onlyOwner
    {
        _setNomineeOwner(newOwner);
    }
}
