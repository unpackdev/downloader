//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./TypeBVaultProxy.sol";
import "./IEventLog.sol";
import "./ITypeBVaultFactory.sol";
import "./VaultFactory.sol";

/// @title A factory that creates a Vault
contract TypeBVaultFactory is VaultFactory, ITypeBVaultFactory { 

    event CreatedTypeBVault(address contractAddress, string name);

    function createTypeB(
        string calldata _name,
        address _token,
        address _owner
    )
        external 
        override
        returns (address)
    {
        require(bytes(_name).length > 0,"name is empty");

        TypeBVaultProxy typeB = new TypeBVaultProxy();

        require(
            address(typeB) != address(0),
            "typeB zero"
        );

        typeB.addProxyAdmin(upgradeAdmin);
        typeB.addAdmin(upgradeAdmin);
        typeB.setImplementation2(vaultLogic, 0, true);

        typeB.setBaseInfoProxy(
            _name,
            _token,
            _owner
        );

        typeB.removeAdmin();

        createdContracts[totalCreatedContracts] = ContractInfo(address(typeB), _name);
        totalCreatedContracts++;

        IEventLog(logEventAddress).logEvent(
            keccak256("TypeBVaultFactory"),
            keccak256("CreatedTypeBVault"),
            address(this),
            abi.encode(address(typeB), _name));

        emit CreatedTypeBVault(address(typeB), _name);

        return address(typeB);
    } 
}