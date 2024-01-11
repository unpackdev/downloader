// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ProxyAdmin.sol";

contract PrimaryLendingPlatformProxyAdmin is ProxyAdmin {
    
    uint256 public constant minimumDelayPeriod = 1 days;

    uint256 public delayPeriod;

    struct UpgradeData {
        uint256 appendTimestamp;
        uint256 delayPeriod;
        address oldImplementation;
        address newImplementation;
    }

    mapping(address => UpgradeData) public upgradeData;

    event SetDelayPeriod(uint256 oldDelayPeriod, uint256 newDelayPeriod);

    event AppendUpgrade(address indexed proxy, uint256 appendTimestamp, uint256 delayPeriod, address oldImplementation, address newImplementation);

    event Upgrade(address indexed proxy, uint256 upgradeTimestamp, address oldImplementation, address newImplementation);

    constructor() {
        delayPeriod = 7 days;
    }

    function setDelayPeriod(uint256 _delayPeriod) public onlyOwner {
        require(minimumDelayPeriod <= _delayPeriod, "PrimaryLendingPlatformProxyAdmin: too low delayPeriod");
        emit SetDelayPeriod(delayPeriod, _delayPeriod);
        delayPeriod = _delayPeriod;
    }

    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public override onlyOwner {
        proxy; newAdmin;
        if (false) {
            delayPeriod++;
        }
        revert("changeProxyAdmin is forbidden");
    }

    function appendUpgrade(TransparentUpgradeableProxy proxy, address newImplementation) public onlyOwner {
        UpgradeData storage _upgrade = upgradeData[address(proxy)];
        if (_upgrade.appendTimestamp != 0) {
            revert("PrimaryLendingPlatformProxyAdmin: wait for next upgrade");
        }
        _upgrade.appendTimestamp = block.timestamp;
        _upgrade.delayPeriod = delayPeriod;
        _upgrade.oldImplementation = getProxyImplementation(proxy);
        _upgrade.newImplementation = newImplementation;
        emit AppendUpgrade(
            address(proxy), 
            _upgrade.appendTimestamp, 
            _upgrade.delayPeriod, 
            _upgrade.oldImplementation, 
            newImplementation
        );
    }

    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public override onlyOwner {
        UpgradeData storage _upgrade = upgradeData[address(proxy)];
        if(_upgrade.appendTimestamp == 0) {
            revert("PrimaryLendingPlatformProxyAdmin: Call first appendUpgrade(...)");
        }
        require(_upgrade.appendTimestamp + _upgrade.delayPeriod <= block.timestamp);
        if (implementation == _upgrade.newImplementation) {
            super.upgrade(proxy, implementation);
            emit Upgrade(address(proxy), block.timestamp, _upgrade.oldImplementation, implementation);
            delete upgradeData[address(proxy)];
        } else {
            // proxy contract dont upgrade the implementation
            delete upgradeData[address(proxy)];
        }
    }

    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable override onlyOwner {
        proxy; implementation; data;
        revert("Use default upgrade()");
    }



}