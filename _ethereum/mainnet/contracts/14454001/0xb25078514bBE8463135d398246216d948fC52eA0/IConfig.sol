// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;
import "./IRegistry.sol";
import "./ISmartAccount.sol";
import "./IPortal.sol";
import "./ISocketRegistry.sol";

interface IConfig {
    function portal() external view returns (IPortal);

    function smartAccountFactory() external view returns (ISmartAccountFactory);

    function registry() external view returns (IRegistry);

    function socketRegistry() external view returns (ISocketRegistry);

    function setPortal(IPortal p) external;

    function setRegistry(IRegistry p) external;

    function setSocketRegistry(ISocketRegistry s) external;

    function setSmartAccountFactory(ISmartAccountFactory b) external;
}
