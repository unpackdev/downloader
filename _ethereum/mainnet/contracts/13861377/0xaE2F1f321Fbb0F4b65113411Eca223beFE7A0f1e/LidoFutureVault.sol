// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
import "./HybridFutureVault.sol";

/**
 * @title Contract for Lido Future
 * @notice Handles the future mechanisms for the Lido protocol
 */
contract LidoFutureVault is HybridFutureVault {
    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     */
    function getIBTRate() public view virtual override returns (uint256) {
        return IBT_UNIT;
    }
}
