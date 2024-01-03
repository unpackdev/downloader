// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

contract SavingsRegistry is Ownable {

    // Available synths which have a savings contract
    address[] public availableSavings;

    // Synth synthetic (proxy) to savings contract
    mapping(address => address) public savings;

    /* ========== Events ========== */

    event SavingsAdded(address synthetic, address savings);
    event SavingsRemoved(address synthetic, address savings);

    /* ========== View Functions ========== */

    function getAllSavings()
        public
        view
        returns (address[] memory)
    {
        return availableSavings;
    }

    /* ========== Mutative Functions ========== */

    /**
     * @dev Add a new savings contract to the registry.
     *
     * @param synthetic The address of the synthetic token proxy contract
     * @param saving The address of the savings contract proxy address
     */
    function addSavings(
        address synthetic,
        address saving
    )
        external
        onlyOwner
    {
        require(
            savings[synthetic] == address(0),
            "Savings already exists"
        );

        availableSavings.push(synthetic);
        savings[synthetic] = saving;

        emit SavingsAdded(synthetic, saving);
    }


    /**
     * @dev Remove a savings contract from registry.
     *
     * @param synthetic The address of the synthetic token proxy contract
     */
    function removeSavings(
        address synthetic
    )
        external
        onlyOwner
    {
        require(
            address(savings[synthetic]) != address(0),
            "Synth does not exist"
        );

        // Save the address we're removing for emitting the event at the end.
        address savingsToRemove = savings[synthetic];

        // Remove the synth from the availableSynths array.
        for (uint i = 0; i < availableSavings.length; i++) {
            if (address(availableSavings[i]) == savingsToRemove) {
                delete availableSavings[i];
                availableSavings[i] = availableSavings[availableSavings.length - 1];
                availableSavings.length--;

                break;
            }
        }

        // And remove it from the synths mapping
        delete savings[synthetic];

        emit SavingsRemoved(synthetic, savingsToRemove);
    }
}
