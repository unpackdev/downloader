// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./ICombatDragons.sol";

contract CombatDragonGiveAwayManager {
    address private manager;
    address private coManager;
    ICombatDragons public combatDragons;

    constructor(
        address _combatDragons,
        address _manager,
        address _coManager
    ) {
        combatDragons = ICombatDragons(_combatDragons);
        manager = _manager;
        coManager = _coManager;
    }

    /**
     * @dev Mints giveaway dragons
     */
    function mintGiveAways(address[] memory recipients) public {
        require(
            msg.sender == manager || msg.sender == coManager,
            "Forbidden action"
        );

        for (uint256 i; i < recipients.length; i++) {
            combatDragons.mint(recipients[i]);
        }
    }
}
