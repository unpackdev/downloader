//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

contract Payer {
    function payout(address payable[] calldata clients, uint256[] calldata amounts) external payable {
        uint256 length = clients.length;
        require(length == amounts.length);

        // transfer the required amount of ether to each one of the clients
        for (uint256 i = 0; i < length; i++)
            clients[i].transfer(amounts[i]);

        // in case you deployed the contract with more ether than required,
        // transfer the remaining ether back to yourself
        payable(msg.sender).transfer(address(this).balance);
    }
}