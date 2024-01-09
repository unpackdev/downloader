// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./HybridFutureVault.sol";
import "./ItfToken.sol";

/**
 * @title Contract for TrueFi Future
 * @notice Handles the future mechanisms for tfTokens
 */
contract TrueFiFutureVault is HybridFutureVault {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     */
    function getIBTRate() public view override returns (uint256) {
        return ItfToken(address(ibt)).poolValue().mul(IBT_UNIT).div(ItfToken(address(ibt)).totalSupply());
    }
}
