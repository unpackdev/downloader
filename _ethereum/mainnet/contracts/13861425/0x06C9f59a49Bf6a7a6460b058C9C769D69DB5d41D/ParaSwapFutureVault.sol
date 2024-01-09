// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./HybridFutureVault.sol";
import "./IsPSPToken.sol";

/**
 * @title Contract for Paraswap Future
 * @notice Handles the future mechanisms for sPSP
 */
contract ParaSwapFutureVault is HybridFutureVault {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     * @dev needs to hold 1 sPSP
     */
    function getIBTRate() public view override returns (uint256) {
        return IsPSPToken(address(ibt)).PSPForSPSP(IBT_UNIT);
    }
}
