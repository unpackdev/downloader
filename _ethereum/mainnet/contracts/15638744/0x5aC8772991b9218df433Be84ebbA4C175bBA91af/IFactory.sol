//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * Represents the external interface of a factory contract.
 */
interface IFactory {

    /**
     * Sets the configurable marketplace address.
     */
    function setMarketplace(
        address marketplace
    ) external;
}
