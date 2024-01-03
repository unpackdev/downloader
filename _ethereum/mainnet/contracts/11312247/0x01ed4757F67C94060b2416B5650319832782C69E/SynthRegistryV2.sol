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

    /**
     * @dev Add a new synth to the registry.
     *
     * @param core The address of the core proxy contract
     * @param synthetic The address of the synthetic token proxy address
     */
    function addSynth(
        address core,
        address synthetic
    )
        external
        onlyOwner
    {
        require(
            synths[core] == address(0),
            "Synth already exists"
        );

        availableSynths.push(synthetic);
        synths[core] = synthetic;

        emit SynthAdded(core, synthetic);
    }


    /**
     * @dev Remove a new synth from registry.
     *
     * @param core The address of the core proxy contract
     */
    function removeSynth(
        address core
    )
        external
        onlyOwner
    {
        require(
            address(synths[core]) != address(0),
            "Synth does not exist"
        );

        // Save the address we're removing for emitting the event at the end.
        address syntheticToRemove = synths[core];

        // Remove the synth from the availableSynths array.
        for (uint i = 0; i < availableSynths.length; i++) {
            if (address(availableSynths[i]) == core) {
                delete availableSynths[i];
                availableSynths[i] = availableSynths[availableSynths.length - 1];
                availableSynths.length--;

                break;
            }
        }

        // And remove it from the synths mapping
        delete synths[core];

        emit SynthRemoved(core, syntheticToRemove);
    }
}
