// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IERC20.sol";

interface IMasterWallet {
    /**
     * @notice Transfers amount of token to the recipient.
     * @dev Requirements:
     * - caller must have role ROLE_MASTER_WALLET_MANAGER
     * @param token Token to transfer.
     * @param recipient Target of the transfer.
     * @param amount Amount to transfer.
     */
    function transfer(IERC20 token, address recipient, uint256 amount) external;
}
