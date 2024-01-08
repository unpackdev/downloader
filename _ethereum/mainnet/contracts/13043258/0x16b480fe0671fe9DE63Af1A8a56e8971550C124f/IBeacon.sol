// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IBeacon {
    /// @notice Logic for this contract.
    function logic() external view returns (address);

    /// @notice Emitted when the logic is updated.
    event Update(address oldLogic, address newLogic);

    /// @notice Updates logic address.
    function update(address newLogic) external;
}
