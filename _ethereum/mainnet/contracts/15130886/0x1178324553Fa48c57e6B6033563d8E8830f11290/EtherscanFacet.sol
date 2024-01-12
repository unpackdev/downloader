// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EtherscanLib.sol";
import "./PausableModifiers.sol";
import "./AccessControlModifiers.sol";

contract EtherscanFacet is PausableModifiers, AccessControlModifiers {
    function setDummyImplementation(address _implementation)
        external
        onlyOperator
        whenNotPaused
    {
        EtherscanLib._setDummyImplementation(_implementation);
    }

    function implementation() external view returns (address) {
        return EtherscanLib._dummyImplementation();
    }
}
