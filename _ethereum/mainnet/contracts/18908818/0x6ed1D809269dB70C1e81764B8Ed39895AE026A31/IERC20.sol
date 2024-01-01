// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IERC20Upgradeable.sol";

/**
 * @title Dollet IERC20
 * @author Dollet Team
 * @notice Default IERC20 interface with additional view methods.
 */
interface IERC20 is IERC20Upgradeable {
    /**
     * @notice Returns the number of decimals used by the token.
     * @return The number of decimals used by the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the name of the token.
     * @return A string representing the token name.
     */
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the token.
     * @return A string representing the token symbol.
     */
    function symbol() external view returns (string memory);
}
