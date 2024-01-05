// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC1155Tradeable.sol";

/**
 * LARRY CARLSON
 * Titled by High Times magazine as “The Salvador Dali of the Next Century” and revered 
 * by many as the Godfather of psychedelic art.   
 * https://larycarlson.com
 * https://facebook.com/THEMASTERLC/  
 * https://instagram.com/larrycarlson/
 * https://twitter.com/LARRYCARLS0N/
 */

/**
 * @title The Official LARRY CARLSON Contract
 * @author Authentix Management Limited <authentix.io>
 * @dev Extends from ERC1155Tradeable 
 */
contract LarryCarlson is ERC1155Tradeable {

    /**
     * @dev Accepts OpenSea Registry address and creates an instance of ERC1155Tradeable.
     * @param _proxyRegistryAddress OpenSea Registry address
     */
    constructor(address _proxyRegistryAddress) 
        ERC1155Tradeable(
            "LARRY CARLSON",
            "LCX",
            _proxyRegistryAddress
        ) 
    {
        _setURI("https://larrycarlson.api.authentix.io/tokens/{id}.json");
    }

}