// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./IVault.sol";
import "./IFlashLoanRecipient.sol";

contract FlashLoanRecipient is IFlashLoanRecipient {
    address private constant vaultAddress = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    IVault private constant vault = IVault(vaultAddress);
    

    function makeFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external {
      vault.flashLoan(this, tokens, amounts, userData);
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        require(msg.sender == vaultAddress);
    }
}