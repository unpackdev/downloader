// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ISquidDepositService.sol";

contract DepositReceiver {
    constructor(bytes memory delegateData, address refundRecipient) {
        // Reading the implementation of the AxelarDepositService
        // and delegating the call back to it
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = ISquidDepositService(msg.sender).receiverImplementation().delegatecall(delegateData);

        // if not success revert with the original revert data
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

        if (refundRecipient == address(0)) refundRecipient = msg.sender;

        selfdestruct(payable(refundRecipient));
    }

    // @dev This function is for receiving Ether from unwrapping WETH9
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
