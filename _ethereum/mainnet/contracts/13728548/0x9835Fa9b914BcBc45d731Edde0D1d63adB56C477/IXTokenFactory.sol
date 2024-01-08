//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IXTokenFactory
 * @author Protofire
 * @dev IXTokenFactory Interface.
 *
 */
interface IXTokenFactory {
    /**
     * @dev deployXToken contract
     */
    function deployXToken(
        address,
        string memory,
        string memory,
        uint8,
        string memory,
        address,
        address
    ) external returns (address);
}
