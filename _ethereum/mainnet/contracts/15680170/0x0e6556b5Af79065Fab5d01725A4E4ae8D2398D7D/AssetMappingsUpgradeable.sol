// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetEventsUpgradeable.sol";
import "./Initializable.sol";

/**
 * @title AssetMappingsUpgradeable
 * @author NeatFi
 * @notice This contract holds the mappings of the protocol storage of NeatFi.
 */
contract AssetMappingsUpgradeable is Initializable, AssetEventsUpgradeable {
    /**
     * @dev Maps the hash of the Order to the Order struct record.
     */
    mapping(bytes32 => Order) public orderInfo;

    /**
     * @dev Maps the hash of the Token to the Token struct record.
     */
    mapping(bytes32 => Token) public tokenInfo;

    /* Initializers */

    function __AssetMappings_init() internal initializer {
        __AssetEvents_init_unchained();
        __AssetMappings_init_unchained();
    }

    function __AssetMappings_init_unchained() internal initializer {}
}
