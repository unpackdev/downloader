//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./TOSVaultProxy.sol";
import "./IEventLog.sol";
import "./ITOSFactory.sol";
import "./VaultFactory.sol";

/// @title A factory that creates a Vault
contract TOSVaultFactory is VaultFactory, ITOSFactory {
    event CreatedTOSVaultProxy(address contractAddress, string name);

    address public owner;

    /// @dev the fixed address of divided Pool
    address public dividedPoolProxy;

    /// @inheritdoc ITOSFactory
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

        TOSVaultProxy _proxy = new TOSVaultProxy();

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
            keccak256("TOSVaultFactory"),
            keccak256("CreatedTOSVaultProxy"),
            address(this),
            abi.encode(address(_proxy), _name));

        emit CreatedTOSVaultProxy(address(_proxy), _name);

        return address(_proxy);
    }

    /// @inheritdoc ITOSFactory
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