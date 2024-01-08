pragma solidity ^0.4.17;


contract Double {
    function () public payable {
        if(block.timestamp % 2 == 0) {
            msg.sender.transfer(msg.value * 2);
        }
    }
}