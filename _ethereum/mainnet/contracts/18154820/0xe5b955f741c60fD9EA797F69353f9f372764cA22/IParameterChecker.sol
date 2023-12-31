// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IParameterChecker {

    /**
     * @dev Return [] on error, return [ 'to' ] if no address to return
     * @param to Destination address of the transaction
     * @param selector Selector of the transaction
     * @param data Data payload of the transaction
     * @return addressList Array of address to be checked with the whitelist
     */
    function getAddressListForChecking(address to, bytes4 selector, bytes memory data) external view returns (address[] memory);
}