// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IAccessControl.sol";
import "./IERC20.sol";

interface ITreasuryStorage {
    struct SpendingLimits {
        //transfer settings
        uint256 maxTotalAmount;
        uint256 maxAmountPerTransfer;
        uint256 maxPercentPerTransfer;
        uint256 minTimeBetweenTransfers;
        // timeframe settings
        uint256 timeframeDuration;
        uint256 maxAmountDuringTimeframe;
    }
    struct SpendingInfo {
        bool isSpenderExist;
        SpendingLimits limits;
        uint256 lastWithdrawalTimestamp;
        uint256 withdrawnDuringTimeframe;
    }

    event TransferFromTreasury(
        address indexed spender,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    function spenders(
        address spender,
        address token
    ) external returns (bool, SpendingLimits calldata, uint256, uint256);

    function initialTimestamp() external returns (uint256);

    function registry() external returns (IAccessControl);
}
