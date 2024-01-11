// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
import "./HybridFutureVault.sol";

/**
 * @title Contract for Aave Future
 * @notice Handles the future mechanisms for aTokens
 */
contract AaveFutureVault is HybridFutureVault {
    function getIBTRate() public view virtual override returns (uint256) {
        return IBT_UNIT;
    }
}
