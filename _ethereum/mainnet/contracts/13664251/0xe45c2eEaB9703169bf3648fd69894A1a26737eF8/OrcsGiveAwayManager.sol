// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./IOrcs.sol";

contract OrcsGiveAwayManager {
    address private manager;
    address private coManager;
    address private secondCoManager;
    IOrcs public orcs;

    constructor(
        address _orcs,
        address _manager,
        address _coManager,
        address _secondCoManager
    ) {
        orcs = IOrcs(_orcs);
        manager = _manager;
        coManager = _coManager;
        secondCoManager = _secondCoManager;
    }

    /**
     * @dev Mints giveaway nfts
     */
    function mintGiveAways(address[] memory recipients) public {
        require(
            msg.sender == manager ||
                msg.sender == coManager ||
                msg.sender == secondCoManager,
            "Forbidden action"
        );

        for (uint256 i; i < recipients.length; i++) {
            orcs.mint(recipients[i]);
        }
    }
}
