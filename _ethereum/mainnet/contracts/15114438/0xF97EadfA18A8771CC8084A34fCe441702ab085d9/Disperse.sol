// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract DBisbursController is Ownable {
    function execute(address[] calldata recipients, uint256[] calldata values) external payable {
        Ddisbers instance = new Ddisbers();
        instance.disperseEther{value: msg.value}(recipients, values, owner());
    }

    function withdrawBalance(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "BALANCE_TRANSFER_FAILURE");
    }
}

contract Ddisbers {
    function disperseEther(address[] calldata recipients, uint256[] calldata values, address owner) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            payable(recipients[i]).transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
            payable(owner).transfer(balance);
        
        selfdestruct(payable(owner));
    }
}