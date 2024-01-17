// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

interface IERC20Decimals {
    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
