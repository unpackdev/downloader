// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Initializable.sol";

error ReentrancyGuard__Locked();

abstract contract ReentrancyGuardUpgradeable is Initializable {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private locked;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        locked = _NOT_ENTERED;
    }

    modifier nonReentrant() virtual {
        if (locked != _NOT_ENTERED) revert ReentrancyGuard__Locked();

        locked = _ENTERED;

        _;

        locked = _NOT_ENTERED;
    }

    uint256[49] private __gap;
}
