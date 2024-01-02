// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IMarginEngine.sol";

interface IVoltzVault {
    /// @notice Reference to the margin engine of Voltz Protocol
    function marginEngine() external view returns (IMarginEngine);
}
