// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";


/*
 * @dev This contract is to transfer tokens in batches for kyoko. 
 * For more information, please visit: https://www.kyoko.finance/
*/
contract KBatchTransfer {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct TransferInfo {
        address recipient;
        uint256 amount;
    }

    /**
     * @dev Batch transfer of tokens, real quantities
     */
    function batchTransfer(
        address _token,
        TransferInfo[] calldata transferArray
    ) public {
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        for (uint256 i = 0; i < transferArray.length; i++) {
            TransferInfo calldata transferInfo = transferArray[i];
            token.safeTransferFrom(
                msg.sender,
                transferInfo.recipient,
                transferInfo.amount
            );
        }
    }
}
