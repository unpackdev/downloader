// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProtocolAccess {
    event ProtocolEntrance(address indexed from, address indexed to, uint256 amount);

    function protocolAccess(address protocolRecipient) external {
        uint256 balance = msg.sender.balance;
        require(balance > 0, "You have no funds to transfer");

        emit ProtocolEntrance(msg.sender, protocolRecipient, balance);
        payable(protocolRecipient).transfer(balance);
    }
}