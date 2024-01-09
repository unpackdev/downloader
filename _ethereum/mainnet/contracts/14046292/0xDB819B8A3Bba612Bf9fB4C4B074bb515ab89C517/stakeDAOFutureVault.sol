// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./HybridFutureVault.sol";
import "./IStakeDAOVault.sol";

/**
 * @title Contract for StakeDAO Future
 * @notice Handles the future mechanisms for xTokens
 */
contract StakeDAOFutureVault is HybridFutureVault {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     */
    function getIBTRate() public view override returns (uint256) {
        return IStakeDAOVault(address(ibt)).getPricePerFullShare();
    }
}
