//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

contract SplitFunds {
    function split(address payable[] calldata recipients, uint256[] calldata amounts) external payable {
        uint256 recipientsLength = recipients.length;
        require(recipientsLength == amounts.length, "ii");

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < recipientsLength; i++) {
            (bool sentToRecipient, bytes memory data) = recipients[i].call{ value: amounts[i] }("");
            totalAmount += amounts[i];
            require(sentToRecipient, "fs");
        }
        require(totalAmount == msg.value, "lc");
    }
}