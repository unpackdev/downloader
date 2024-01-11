// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Proxied.sol";

contract GaugeRegistry is Proxied {
    address[] public gauges;
    mapping(address => address) public gaugeToVault;

    event AddGauge(address gauge, address vault);
    event RemoveGauge(address gauge, address vault);

    constructor() {} // solhint-disable no-empty-blocks

    function addGauge(address newGauge, address vault) external onlyProxyAdmin {
        require(
            gaugeToVault[newGauge] == address(0),
            "GaugeRegistry: gauge already added"
        );
        gauges.push(newGauge);
        gaugeToVault[newGauge] = vault;
        emit AddGauge(newGauge, vault);
    }

    function removeGauge(address gauge) external onlyProxyAdmin {
        _removeFromArray(gauge);
        emit RemoveGauge(gauge, gaugeToVault[gauge]);
        delete gaugeToVault[gauge];
    }

    function _removeFromArray(address target) internal {
        uint256 index = 1 ether;
        address[] memory _gauges = gauges;
        for (uint256 i = 0; i < _gauges.length; i++) {
            if (_gauges[i] == target) {
                index = i;
                break;
            }
        }
        require(index < 1 ether, "GaugeRegistry: element not found");
        gauges[index] = _gauges[_gauges.length - 1];
        gauges.pop();
    }
}
