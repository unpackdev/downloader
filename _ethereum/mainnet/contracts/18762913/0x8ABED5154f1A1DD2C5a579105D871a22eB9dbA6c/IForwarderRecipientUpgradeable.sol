// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title IForwarderRecipientUpgradeable
 * @author pNetwork
 *
 * @notice
 */
interface IForwarderRecipientUpgradeable {
    /*
     * @notice Returns the forwarder address. This is the address that is allowed to invoke the call if the 'onlyForwarder' modifier is used.
     *
     * @return forwarder address.
     */
    function forwarder() external view returns (address);

    /*
     * @notice Set the forwarder address.
     *
     * @param forwarder_ forwarder address.
     */
    function setForwarder(address forwarder_) external;
}
