// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./ProxyBeacon.sol";
import "./PublicBeaconProxy.sol";

import "./IDepositAddressMaker.sol";
import "./IDepositMover.sol";

contract DepositAddressMaker is IDepositAddressMaker, OwnableUpgradeable, UUPSUpgradeable {
    ProxyBeacon public override depositMoverBeacon;

    address public override hotwallet;

    address[] public override depositMoverContracts;

    function __DepositAddressMaker_init(
        address hotwallet_,
        address depositMoverImplAddr_
    ) external override initializer {
        __Ownable_init();

        depositMoverBeacon = new ProxyBeacon();
        hotwallet = hotwallet_;

        _setNewImplementation(depositMoverImplAddr_);
    }

    function setNewImplementation(address newImplementation_) external override onlyOwner {
        _setNewImplementation(newImplementation_);
    }

    function setHotwallet(address newHotwallet_) external override onlyOwner {
        hotwallet = newHotwallet_;
    }

    function deployDepositMover(
        address executorAddr_,
        address massDepositMoverAddr_
    ) external override onlyOwner {
        if (executorAddr_ == address(0)) {
            revert DepositAddressMakerZeroExecutorAddress();
        }

        address newDepositMoverProxy_ = address(
            new PublicBeaconProxy(address(depositMoverBeacon), "")
        );

        IDepositMover(newDepositMoverProxy_).__DepositMover_init(
            this,
            massDepositMoverAddr_,
            executorAddr_
        );

        depositMoverContracts.push(newDepositMoverProxy_);

        emit DepositMoverDeployed(newDepositMoverProxy_, executorAddr_, massDepositMoverAddr_);
    }

    function getDepositMoverContractsCount() external view override returns (uint256) {
        return depositMoverContracts.length;
    }

    function getDepositMoverImpl() external view override returns (address) {
        return depositMoverBeacon.implementation();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _setNewImplementation(address newImplementation_) internal {
        if (depositMoverBeacon.implementation() != newImplementation_) {
            depositMoverBeacon.upgrade(newImplementation_);
        }
    }
}
