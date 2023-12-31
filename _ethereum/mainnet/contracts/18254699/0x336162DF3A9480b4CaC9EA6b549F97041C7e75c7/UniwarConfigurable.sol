// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./IUniwarConfig.sol";

abstract contract UniwarConfigurable is OwnableUpgradeable, UUPSUpgradeable {
    IUniwarConfig public config;

    event UpdateConfig(address indexed _oldConfig, address indexed _newConfig);

    function __UniwarConfigurable_init(address _config) internal onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __UniwarConfigurable_init_unchained(_config);
    }

    function __UniwarConfigurable_init_unchained(address _config) internal onlyInitializing {
        _updateConfig(_config);
    }

    function updateConfig(address _config) external onlyOwner {
        _updateConfig(_config);
    }

    function _updateConfig(address _newConfig) internal {
        require(_newConfig != address(0), "UniwarConfigurable: invalid config address");

        address _oldConfig = address(config);
        config = IUniwarConfig(_newConfig);
        emit UpdateConfig(_oldConfig, _newConfig);
    }
}
