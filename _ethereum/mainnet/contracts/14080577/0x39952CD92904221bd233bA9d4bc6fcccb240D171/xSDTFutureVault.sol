// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./HybridFutureVault.sol";
import "./IERC20.sol";

/**
 * @title Contract for StakeDAO Future
 * @notice Handles the future mechanisms for xTokens
 */
contract xSDTFutureVault is HybridFutureVault {
    using SafeMathUpgradeable for uint256;

    address public constant STAKED_TOKEN = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;

    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     */
    function getIBTRate() public view override returns (uint256) {
        return IERC20(STAKED_TOKEN).balanceOf(address(ibt)).mul(IBT_UNIT).div(ibt.totalSupply());
    }
}
