//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./TONVaultProxy.sol";
import "./IEventLog.sol";
import "./ITONFactory.sol";
import "./VaultFactory.sol";

/// @title A factory that creates a Vault
contract TONVaultFactory is VaultFactory, ITONFactory {
    event CreatedTONVaultProxy(address contractAddress, string name);

    address public owner;

    /// @dev the fixed address of divided Pool
    address public dividedPoolProxy;

    /// @inheritdoc ITONFactory
    function create(
        string calldata _name,
        address _token,
        address _owner
    )
        external
        override
        returns (address)
    {
        require(bytes(_name).length > 0,"name is empty");

        TONVaultProxy _proxy = new TONVaultProxy();

        require(
            address(_proxy) != address(0),
            "proxy zero"
        );

        _proxy.addProxyAdmin(upgradeAdmin);
        _proxy.addAdmin(upgradeAdmin);
        _proxy.setImplementation2(vaultLogic, 0, true);

        _proxy.setBaseInfoProxy(
            _name,
            _token,
            _owner,
            dividedPoolProxy
        );

        _proxy.removeAdmin();

        createdContracts[totalCreatedContracts] = ContractInfo(address(_proxy), _name);
        totalCreatedContracts++;

        IEventLog(logEventAddress).logEvent(
            keccak256("TONVaultFactory"),
            keccak256("CreatedTONVaultProxy"),
            address(this),
            abi.encode(address(_proxy), _name));

        emit CreatedTONVaultProxy(address(_proxy), _name);

        return address(_proxy);
    }

    /// @inheritdoc ITONFactory
    function setinfo(
        address _dividedPool
    )
        external
        override
        onlyOwner
    {
        dividedPoolProxy = _dividedPool;
    }

}