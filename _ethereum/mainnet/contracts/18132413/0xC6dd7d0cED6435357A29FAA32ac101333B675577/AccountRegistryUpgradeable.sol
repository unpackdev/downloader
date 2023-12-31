// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./BaseUpgradeable.sol";
import "./IERC6551Registry.sol";
import "./Constants.sol";

contract AccountRegistryUpgradeable is BaseUpgradeable {
    IERC6551Registry internal _registry;
    address internal _implementation;

    function __AccountRegistryUpgradeable_init(
        IERC6551Registry registry_,
        address implementation_
    ) internal onlyInitializing {
        __AccountRegistryUpgradeable_init_unchained(registry_, implementation_);
    }

    function __AccountRegistryUpgradeable_init_unchained(
        IERC6551Registry registry_,
        address implementation_
    ) internal onlyInitializing {
        _setRegistryInfo(registry_, implementation_);
    }

    function _setRegistryInfo(IERC6551Registry registry_, address implementation_) internal {
        _registry = registry_;
        _implementation = implementation_;
    }

    function setRegistryInfo(IERC6551Registry registry_, address implementation_) external onlyRole(OPERATOR_ROLE) {
        _setRegistryInfo(registry_, implementation_);
    }

    uint256[48] private __gap;
}
