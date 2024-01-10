// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./HybridFutureVault.sol";
import "./IiFarm.sol";

/**
 * @title Contract for Harvest Future
 * @notice Handles the future mechanisms for harvest ibt
 */
contract HarvestFutureVault is HybridFutureVault {
    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     */
    function getIBTRate() public view override returns (uint256) {
        return IiFarm(address(ibt)).getPricePerFullShare();
    }
}
