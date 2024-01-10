//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOwnable.sol";
import "./IShellFramework.sol";

// Factory that deploys new collections on the shell platform
interface IShellFactory is IOwnable {
    // an implementation with a specific name already exists
    error ImplementationExists();

    // an implementation being added did not support IShellFramework
    error InvalidImplementation();

    // an implementation with a specific name was not found
    error ImplementationNotFound();

    // new contract implementation added
    event ImplementationRegistered(string name, IShellFramework implementation);

    // new clone launched
    event CollectionCreated(
        IShellFramework collection,
        IShellFramework implementation
    );

    // register a new collection implementation
    function registerImplementation(
        string calldata name,
        IShellFramework implementation
    ) external;

    // deploy a new (cloned) collection
    function createCollection(
        string calldata name,
        string calldata symbol,
        string calldata implementationName,
        IEngine engine,
        address owner
    ) external returns (IShellFramework);
}
