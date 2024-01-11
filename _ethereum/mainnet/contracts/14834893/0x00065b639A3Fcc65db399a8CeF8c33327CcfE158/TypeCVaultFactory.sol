//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./TypeCVaultProxy.sol";
import "./IEventLog.sol";
import "./ITypeCVaultFactory.sol";
import "./VaultFactory.sol";

/// @title A factory that creates a Vault
contract TypeCVaultFactory is VaultFactory, ITypeCVaultFactory { 

    event CreatedTypeCVault(address contractAddress, string name);

    function createTypeC(
        string calldata _name,
        address _token,
        address _owner
    )
        external 
        override
        returns (address)
    {
        require(bytes(_name).length > 0,"name is empty");

        TypeCVaultProxy typeC = new TypeCVaultProxy();

        require(
            address(typeC) != address(0),
            "typeC zero"
        );

        typeC.addProxyAdmin(upgradeAdmin);
        typeC.addAdmin(upgradeAdmin);
        typeC.setImplementation2(vaultLogic, 0, true);

        typeC.setBaseInfoProxy(
            _name,
            _token,
            _owner
        );

        typeC.removeAdmin();

        createdContracts[totalCreatedContracts] = ContractInfo(address(typeC), _name);
        totalCreatedContracts++;

        IEventLog(logEventAddress).logEvent(
            keccak256("TypeCVaultFactory"),
            keccak256("CreatedTypeCVault"),
            address(this),
            abi.encode(address(typeC), _name));

        emit CreatedTypeCVault(address(typeC), _name);

        return address(typeC);
    } 
}