// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface ISailorSwapPoolFactoryEventsAndErrors {
    error NotERC721();
    error AlreadyDeployed();

    event NewPoolCreated(address deployment, address creator, address collection);
}
