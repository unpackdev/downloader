// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BeaconProxy.sol";
import "./UpgradeableBeacon.sol";
import "./Ownable.sol";

interface ILogic {
    function transferOwnership(address _newOwner) external;
}

contract MirrorFactory is Ownable {
    UpgradeableBeacon immutable upgradeableBeacon;

    address[] public vaults;

    constructor(address _logic) {
        upgradeableBeacon = new UpgradeableBeacon(_logic);
    }

    function updateLogic(address _newImpl) onlyOwner external {
        upgradeableBeacon.upgradeTo(_newImpl);
    }

    function createVault(bytes calldata _data) external onlyOwner returns (address _proxyAddress){
        BeaconProxy proxy = new BeaconProxy(address(upgradeableBeacon), _data);
        _proxyAddress = address(proxy);
        ILogic(_proxyAddress).transferOwnership(msg.sender);
        vaults.push(address(proxy));
    }

    function getVault(uint _index) external view returns (address) {
        return vaults[_index];
    }

    function getVaultLength() external view returns (uint) {
        return vaults.length;
    }
}
