// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "./LibAppStorage.sol";

contract EditMaxAllowedFacet is Modifiers {
    /// Set max allowed per transaction
    function setMaxAllowed(uint256 maxAllowed) external onlyEditor {
        s._maxAllowed = maxAllowed;
    }

    /// Returns price in WEI
    function getMaxAllowed() external view returns (uint256) {
        return s._maxAllowed;
    }
}
