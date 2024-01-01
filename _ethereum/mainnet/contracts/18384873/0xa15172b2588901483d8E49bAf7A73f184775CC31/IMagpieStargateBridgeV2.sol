// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./LibTransferKey.sol";

interface IMagpieStargateBridgeV2 {
    struct Settings {
        address aggregatorAddress;
        address routerAddress;
    }

    function updateSettings(Settings calldata _settings) external;

    struct WithdrawArgs {
        address assetAddress;
        TransferKey transferKey;
    }

    function withdraw(WithdrawArgs calldata withdrawArgs) external returns (uint256 amountOut);

    function sgReceive(
        uint16,
        bytes calldata,
        uint256,
        address assetAddress,
        uint256 amount,
        bytes calldata payload
    ) external;
}
