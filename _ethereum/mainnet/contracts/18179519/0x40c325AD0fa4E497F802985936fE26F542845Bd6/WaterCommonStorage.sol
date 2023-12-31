// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IBeanstalkUpgradeable.sol";
import "./IERC1155Upgradeable.sol";

library WaterCommonStorage {
    struct Layout {
        // Beanstalk protocol contract
        IBeanstalkUpgradeable beanstalk;
        // fertilizer token contract
        IERC1155Upgradeable fertilizer;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("irrigation.contracts.storage.WaterCommon");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
