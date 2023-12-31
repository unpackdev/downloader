// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IMapleTokenProxy {

    /**
     *  @dev   Emitted when the implementation address is set.
     *  @param implementation The address of the new implementation.
     */
    event ImplementationSet(address indexed implementation);

    /**
     *  @dev   Sets the implementation address.
     *  @param newImplementation The address to set the implementation to.
     */
    function setImplementation(address newImplementation) external;

}
