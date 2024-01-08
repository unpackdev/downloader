pragma solidity >=0.8.0;

import "./IConfig.sol";

contract Base {
    event ConfigUpdated(address indexed owner, address indexed config);

    IConfig internal config;

    modifier onlyCEO() {
        require(msg.sender == config.ceo(), "only CEO");
        _;
    }

    constructor(address _configAddr) {
        require(_configAddr != address(0), "config address = 0");
        config = IConfig(_configAddr);
    }

    function updateConfig(address _config) external onlyCEO() {
        require(_config != address(0), "config address = 0");
        require(address(config) != _config, "address identical");
        config = IConfig(_config);
        emit ConfigUpdated(msg.sender, _config);
    }

    function configAddress() external view returns (address) {
        return address(config);
    }

    function getConfig() external view returns (IConfig) {
        return config;
    }
}
