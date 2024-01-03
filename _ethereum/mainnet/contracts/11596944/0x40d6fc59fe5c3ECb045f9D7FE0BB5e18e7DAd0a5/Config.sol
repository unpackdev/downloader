// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.11;

import "./Governable.sol";

contract Config is Governable {

    event ConfigSet(bytes32 config, uint256 value);

    mapping (bytes32 => uint256) private _config;

    function initialize() external initializer {
        super.initialize(msg.sender);
         setConfig("PROVIDER_MINIMUM_ANKR_STAKING", 100000 ether);
         setConfig("PROVIDER_MINIMUM_ETH_STAKING", 2 ether);
         setConfig("REQUESTER_MINIMUM_POOL_STAKING", 500 finney);
         setConfig("EXIT_BLOCKS", 24);
    }

    function setConfig(bytes32 config, uint256 value) public governance {
        _config[config] = value;
    }

    function getConfig(bytes32 config) public view returns(uint256) {
        return _config[config];
    }

    uint256[50] private __gap;
}