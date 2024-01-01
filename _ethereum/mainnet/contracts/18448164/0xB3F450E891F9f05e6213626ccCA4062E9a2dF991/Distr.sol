// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherDistributor {
    uint public totalAmountReceived;
    uint public totalReceivers;
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function distributeEther(address[] calldata receivers) external payable {
        require(receivers.length > 0, "No receivers specified");
        
        totalAmountReceived += msg.value;
        totalReceivers += receivers.length;
        uint amountPerReceiver = msg.value / receivers.length;
        
        require(amountPerReceiver > 0, "Insufficient ether to send to each receiver");
        
        for (uint i = 0; i < receivers.length; i++) {
            payable(receivers[i]).transfer(amountPerReceiver);
        }
    }
    
    function withdrawExcessEther() external {
        require(msg.sender == owner, "Only the contract owner can withdraw excess ether");
       
        
        payable(msg.sender).transfer(address(this).balance);
    }
}