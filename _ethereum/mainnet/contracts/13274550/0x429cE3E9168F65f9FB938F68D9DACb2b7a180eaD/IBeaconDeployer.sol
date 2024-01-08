// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IBeaconDeployer {

    event Deployed(string name, address indexed proxy);

    event Upgraded(address implementation);

    function deployNewContract(bytes calldata data) external returns (address);

    function deployNewNamedContract(string memory name, bytes calldata data) external returns (address);

    function upgradeTo(address newImplementation) external;

    function getContractByName(string memory name) external view returns (address);
}
