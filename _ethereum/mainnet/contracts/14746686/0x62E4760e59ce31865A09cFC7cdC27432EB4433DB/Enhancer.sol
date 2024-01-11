// SPDX-License-Identifier: MIT

/// @title RaidParty Helper Contract for Enhancers

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./IEnhancer.sol";

contract Enhancer is IEnhancer {
    function onEnhancement(uint256[] calldata, uint8[] calldata)
        public
        virtual
        override
        returns (bytes4)
    {
        return this.onEnhancement.selector;
    }
}
