// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

import "./ISyntheticToken.sol";
import "./IERC20.sol";

contract SynthRegistryV2 is Ownable {

    // Available Synths which can be used with the system
    address[] public availableSynths;

    // Synth address (proxy) to synthetic token
    mapping(address => address) public synths;

    /* ========== Events ========== */

    event SynthAdded(address proxy, address synth);
    event SynthRemoved(address proxy, address synth);

    /* ========== View Functions ========== */

    function getAllSynths()
        public
        view
        returns (address[] memory)
    {
        return availableSynths;
    }

    /* ========== Mutative Functions ========== */

    function addSynth(
        address proxy,
        address synth
    )
        external
        onlyOwner
    {
        require(
            synths[proxy] == address(0),
            "Synth already exists"
        );

        availableSynths.push(synth);
        synths[proxy] = synth;

        emit SynthAdded(proxy, synth);
    }

    function removeSynth(
        address proxy
    )
        external
        onlyOwner
    {
        require(
            address(synths[proxy]) != address(0),
            "Synth does not exist"
        );

        // Save the address we're removing for emitting the event at the end.
        address syntheticToRemove = synths[proxy];

        // Remove the synth from the availableSynths array.
        for (uint i = 0; i < availableSynths.length; i++) {
            if (address(availableSynths[i]) == proxy) {
                delete availableSynths[i];
                availableSynths[i] = availableSynths[availableSynths.length - 1];
                availableSynths.length--;

                break;
            }
        }

        // And remove it from the synths mapping
        delete synths[proxy];

        emit SynthRemoved(proxy, syntheticToRemove);
    }
}
