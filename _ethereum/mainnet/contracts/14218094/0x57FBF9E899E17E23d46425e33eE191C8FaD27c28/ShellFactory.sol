//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
                   ShellFactory V1

        ███████╗██╗  ██╗███████╗██╗     ██╗
        ██╔════╝██║  ██║██╔════╝██║     ██║
        ███████╗███████║█████╗  ██║     ██║
        ╚════██║██╔══██║██╔══╝  ██║     ██║
        ███████║██║  ██║███████╗███████╗███████╗
        ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝

           An open product framework for NFTs
            Dreamt up & built at Playgrounds

               https://heyshell.xyz
              https://playgrounds.wtf

*/

import "./Clones.sol";
import "./Ownable.sol";
import "./IShellFactory.sol";

contract ShellFactory is IShellFactory, Ownable {
    mapping(string => IShellFramework) public implementations;

    constructor() {
        _transferOwnership(msg.sender);
    }

    function registerImplementation(
        string calldata name,
        IShellFramework implementation
    ) external onlyOwner {
        if (implementations[name] != IShellFramework(address(0))) {
            revert ImplementationExists();
        }

        bool isValid = implementation.supportsInterface(
            type(IShellFramework).interfaceId
        );
        if (!isValid) {
            revert InvalidImplementation();
        }

        implementations[name] = implementation;
        emit ImplementationRegistered(name, implementation);
    }

    function createCollection(
        string calldata name,
        string calldata symbol,
        string calldata implementationName,
        IEngine engine,
        address owner
    ) external returns (IShellFramework) {
        IShellFramework implementation = implementations[implementationName];
        if (implementation == IShellFramework(address(0))) {
            revert ImplementationNotFound();
        }

        IShellFramework clone = IShellFramework(
            Clones.clone(address(implementation))
        );
        clone.initialize(name, symbol, engine, owner);
        emit CollectionCreated(clone, implementation);

        return clone;
    }
}
