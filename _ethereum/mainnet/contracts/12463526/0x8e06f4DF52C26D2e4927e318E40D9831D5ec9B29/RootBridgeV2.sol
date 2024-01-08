// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import "./ClientBridge.sol";
import "./IPriceFeed.sol";

contract RootBridgeV2 is ClientBridge {
    /**
     * @notice set minimum deposit amount for different tokens
     */
    function setMinDepositAmount(IERC20 _token, Decimal.decimal memory _amount) external onlyOwner {
        minWithdrawalAmountMap[address(_token)] = _amount;
    }

    function setMinWithdrawalAmount(IERC20 _token, Decimal.decimal memory _amount) external override onlyOwner {
        revert("not support");
    }
}
