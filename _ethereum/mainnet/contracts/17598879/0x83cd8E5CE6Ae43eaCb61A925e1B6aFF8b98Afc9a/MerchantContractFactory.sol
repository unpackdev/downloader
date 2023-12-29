pragma solidity 0.8.14;
// SPDX-License-Identifier: MIT

import "./BeaconProxy.sol";
import "./Ownable.sol";
import "./MerchantContract.sol";
import "./MerchantContractBeacon.sol";

contract MerchantContractFactory is Ownable {
    mapping(string => address) private merchantContracts;

    MerchantContractBeacon immutable beacon;

    event MerchantContractDeployed(
        string organizationId,
        address merchantContractAddress
    );

    constructor(address _initImplementation) {
        beacon = new MerchantContractBeacon(_initImplementation);
        transferOwnership(tx.origin);
    }

    function createMerchantContract(
        string memory _organizationId
    ) external onlyOwner returns (address) {
        BeaconProxy proxy = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                MerchantContract(address(0)).initialize.selector,
                _organizationId
            )
        );

        merchantContracts[_organizationId] = address(proxy);

        emit MerchantContractDeployed(_organizationId, address(proxy));
        return address(proxy);
    }

    function getMerchantContract(
        string memory organizationId
    ) external view returns (address) {
        return merchantContracts[organizationId];
    }

    function getBeacon() public view returns (address) {
        return address(beacon);
    }

    function getImplementation() public view returns (address) {
        return beacon.implementation();
    }
}
