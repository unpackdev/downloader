// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// external
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ContextUpgradeable.sol";

import "./IAccessControlUpgradeable.sol";
import "./IBaseUpgradeable.sol";
import "./IRoleManagerUpgradeable.sol";
import "./Constants.sol";

contract BaseUpgradeable is IBaseUpgradeable, Initializable, UUPSUpgradeable, ContextUpgradeable {
    address public override roleManager;

    modifier onlyRole(bytes32 role) {
        if (!_checkRole(role)) revert BaseUpgradeable__NotAuthorized();
        _;
    }

    function __BaseUpgradeable_init(address roleManager_) internal onlyInitializing {
        __BaseUpgradeable_init_unchained(roleManager_);
    }

    function __BaseUpgradeable_init_unchained(address roleManager_) internal onlyInitializing {
        roleManager = roleManager_;
    }

    function setRoleManager(address roleManager_) external override onlyRole(UPGRADER_ROLE) {
        roleManager = roleManager_;
    }

    function _call(Operation memory operation_) internal returns (bytes memory result) {
        bool success;
        (success, result) = operation_.to.call{ value: operation_.value }(operation_.data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {}

    function _checkRole(bytes32 role) internal view returns (bool) {
        if (IAccessControlUpgradeable(roleManager).hasRole(role, _msgSender())) return true;

        return false;
    }

    uint256[49] private __gap;
}
