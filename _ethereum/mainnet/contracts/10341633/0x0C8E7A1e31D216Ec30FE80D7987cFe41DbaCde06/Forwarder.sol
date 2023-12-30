pragma solidity ^0.5.16;
contract Forwarder  {
    address payable public destinationAddress;

    constructor() public {
        destinationAddress = msg.sender;
    }

    function () external payable {
        if (msg.value > 0) {
            destinationAddress.transfer(msg.value);
        }
    }
}