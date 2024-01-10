// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./IEditions.sol";

interface IEditionsFactoryEvents {
    event EditionsDeployed(
        address indexed owner,
        address indexed clone,
        address indexed implementation
    );

    event TributaryRegistrySet(
        address indexed oldTributaryRegistry,
        address indexed newTributaryRegistry
    );

    event ImplementationSet(
        address indexed oldImplementation,
        address indexed newImplementation
    );
}

interface IEditionsFactory {
    function setImplementation(address implementation_) external;

    function setTributaryRegistry(address tributaryRegistry_) external;

    function create(
        address owner,
        address tributary,
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory contentURI_,
        string memory animationURI_,
        string memory contractURI_,
        IEditions.Edition memory edition_,
        uint256 nonce,
        bool paused_
    ) external returns (address clone);

    function predictDeterministicAddress(address implementation_, bytes32 salt)
        external
        view
        returns (address);
}
