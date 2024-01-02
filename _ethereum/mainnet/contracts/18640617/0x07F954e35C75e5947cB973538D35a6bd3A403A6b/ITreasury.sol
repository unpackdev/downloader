// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITreasury {
    event Withdrawn(
        address indexed asset,
        address indexed receiver,
        uint256 amount
    );

    event StuckAssetsAdded(
        address indexed asset,
        address indexed receiver,
        uint256 amount
    );

    receive() external payable;

    /**
     * @dev Withdraw funds from the treasury
     * @param asset Address of the asset (0 for native token)
     * @param receiver Address of the withdrawal receiver
     * @param amount The amount of funds to withdraw.
     * @param trustedReceiver Flag if we trust that receiver won't revert withdrawal
     */
    function withdraw(
        address asset,
        address receiver,
        uint256 amount,
        bool trustedReceiver
    ) external;

    function withdrawStuckAssets(address asset, address receiver) external;
}
