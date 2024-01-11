// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

import "./IERC165.sol";
import "./ISingleton.sol";
import "./SelfAuthorized.sol";

/**
 * @title Singleton - Base for singleton contracts (should always be first super contract).
 * This contract is tightly coupled to our proxy contract (see `proxies/LaserProxy.sol`).
 */
contract Singleton is SelfAuthorized, ISingleton {
    // Singleton always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address public singleton;

    /**
     * @dev Migrates to a new singleton (implementation).
     * @param _singleton New implementation address.
     */
    function upgradeSingleton(address _singleton) external authorized {
        if (_singleton == address(this))
            revert Singleton__upgradeSingleton__incorrectAddress();

        if (!IERC165(_singleton).supportsInterface(0xae029e0b)) {
            //bytes4(keccak256("I_AM_LASER")))
            revert Singleton__upgradeSingleton__notLaser();
        } else {
            singleton = _singleton;
            emit SingletonChanged(_singleton);
        }
    }
}
