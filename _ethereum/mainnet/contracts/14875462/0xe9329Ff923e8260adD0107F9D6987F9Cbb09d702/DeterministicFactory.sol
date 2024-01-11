// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {CREATE3} from "CREATE3.sol";
import {AdminUpgradeabilityProxy} from "AdminUpgradeabilityProxy.sol";

/// WARNING: Dont use this to deploy proxy contracts where the msg.sender is used in the initialize method.

/// @title For deterministic deployment of proxy contracts
/// @notice deploys a proxy contract for the _logic contract address provided
/// the contract address only depends on the salt provided. For the same salt, it will deploy contracts with the same address on any chain
/// use the getDeployed() method to view the address for your to be deployed contract in advance
contract DeterministicFactory {
    event NewContractDeployed(address proxy, address logic, address admin);

    /// @notice deploys a new proxy contract for the _logic contract provided
    /// @param salt the key which determines the contract address. Keep this same on multiple chains to deploy contracts with the same address
    /// @param value the value to send to the proxy contract if any
    /// @param _admin the admin of the proxy contract (the address that can change the proxy implementation)
    /// @param _data encoded data of the initialization method to call on the proxy contract
    /// @return proxy the address of the proxy contract deployed for the _logic contract
    function deploy(
        bytes32 salt,
        uint256 value,
        address _logic,
        address _admin,
        bytes memory _data
    ) public returns (address proxy) {
        proxy = CREATE3.deploy(
            salt,
            abi.encodePacked(
                type(AdminUpgradeabilityProxy).creationCode,
                abi.encode(_logic, _admin, _data)
            ),
            value
        );
        emit NewContractDeployed(proxy, _logic, _admin);
    }

    /// @notice will return the expected contract address if this salt is used in the deploy() method
    function getDeployed(bytes32 salt) public view returns (address) {
        return CREATE3.getDeployed(salt);
    }
}
