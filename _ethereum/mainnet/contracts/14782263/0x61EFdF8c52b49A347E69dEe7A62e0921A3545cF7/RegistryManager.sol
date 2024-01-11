// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "./Initializable.sol";
import "./IRegistry.sol";

/**
    Error codes:
    - M1 = ERROR_REGISTRY_MANAGER_ONLY_REGISTRY_MANAGER_ROLE
    - M2 = ERROR_REGISTRY_MANAGER_ONLY_CORE_CONFIGURATION_UPDATER_ROLE
 */
contract RegistryManager is Initializable {
    event LogRegistryChanged(address indexed _changer, address indexed _newRegistryAddress);

    IRegistry internal registry;

    modifier onlyRegistryManager() {
        require(registry.isRegistryManager(msg.sender), "M1");
        _;
    }

    modifier onlyCoreConfigurationUpdater() {
        require(registry.isCoreConfigurationUpdater(msg.sender), "M2");
        _;
    }

    function __RegistryManager__init(address _registry) internal initializer {
        require(_registry != address(0));
        registry = IRegistry(_registry);
        emit LogRegistryChanged(msg.sender, _registry);
    }

    function setRegistry(address _registry) external onlyRegistryManager {
        registry = IRegistry(_registry);
        emit LogRegistryChanged(msg.sender, _registry);
    }

    function getRegistry() external view returns (address) {
        return address(registry);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private __gap;
}
