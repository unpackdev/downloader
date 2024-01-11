// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./AccessControlEnumerableUpgradeable.sol";

/**
 * @dev Treasury
 */
contract Collector is AccessControlEnumerableUpgradeable {

    uint256 public constant COLLECTOR_REVISION = 0x1;
    bytes32 public constant COLLECTOR_ADMIN = keccak256("COLLECTOR_ADMIN");

    modifier onlyCollectorAdmin() {
        require(
            hasRole(COLLECTOR_ADMIN, _msgSender()),
            "Only the collecor admin has permission to do this operation"
        );
        _;
    }

    /**
     * @dev initializes the contract
     */
    function initialize() public initializer {
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }


}
