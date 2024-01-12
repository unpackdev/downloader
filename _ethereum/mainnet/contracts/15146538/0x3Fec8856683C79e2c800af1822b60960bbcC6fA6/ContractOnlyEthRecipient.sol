// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./Errors.sol";

contract ContractOnlyEthRecipient {
    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender == tx.origin) {
            revert DirectEthDepositIsForbidden();
        }
    }
}
