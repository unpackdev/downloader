// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./Ownable.sol";

contract Beacon is Ownable {
    /// @notice Logic for this contract.
    address public logic;

    /// @notice Emitted when the logic is updated.
    event Updated(address oldLogic, address newLogic);

    constructor(address owner_) Ownable(owner_) {}

    /**
     * @notice Updates logic address.
     */
    function update(address newLogic) public onlyOwner {
        // Ensure that the newLogic contract is not the null address.
        require(newLogic != address(0), "Must specify logic.");

        // Ensure that the logic contract has code via extcodesize.
        uint256 logicSize;
        assembly {
            logicSize := extcodesize(newLogic)
        }
        require(logicSize > 0, "Logic must have contract code.");

        emit Updated(logic, newLogic);

        // Update logic
        logic = newLogic;
    }
}
