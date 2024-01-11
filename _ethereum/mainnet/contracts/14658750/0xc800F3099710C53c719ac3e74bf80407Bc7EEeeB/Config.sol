// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;
import "./AccessControlEnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IConfig.sol";
import "./IRegistry.sol";
import "./ISmartAccount.sol";
import "./IPortal.sol";
import "./ISocketRegistry.sol";

contract Config is
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    IConfig
{
    IPortal public override portal;
    IRegistry public override registry;
    ISocketRegistry public override socketRegistry;
    ISmartAccountFactory public override smartAccountFactory;

    function _initialize() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setPortal(IPortal p)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        portal = p;
        emit PortalSet(p);
    }

    function setRegistry(IRegistry p)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        registry = p;
        emit RegistrySet(p);
    }

    function setSocketRegistry(ISocketRegistry s)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        socketRegistry = s;
        emit SocketRegistrySet(s);
    }

    function setSmartAccountFactory(ISmartAccountFactory b)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        smartAccountFactory = b;
        emit SmartContractFactorySet(b);
    }
}
