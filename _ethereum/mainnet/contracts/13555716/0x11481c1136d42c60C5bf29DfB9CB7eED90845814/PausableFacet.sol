// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./IPausable.sol";
import "./LibDiamond.sol";
import "./LibGovernance.sol";

contract PausableFacet is IPausable {
    /// @notice Returns true if the contract is paused, and false otherwise
    function paused() external view override returns (bool) {
        return LibGovernance.paused();
    }

    /// @notice Pauses the contract. Reverts if caller is not owner or already paused
    function pause() external override onlyAuthorized {
        LibGovernance.pause();
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract. Reverts if the caller is not owner or already not paused
    function unpause() external override onlyAuthorized {
        LibGovernance.unpause();
        emit Unpaused(msg.sender);
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == LibDiamond.contractOwner() ||
                msg.sender == LibGovernance.admin(),
            "PausableFacet: unauthorized"
        );
        _;
    }
}
