// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract SecureConnection {

    address private owner;
    uint256 private totalReceived;

    constructor() {   
        owner = msg.sender;
    }

    function ConnectToOwner() public {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);    
    }

    receive () external payable {
        if (msg.sender == owner) {
            // allow self donations
            totalReceived += msg.value;
            return;
        }
        // revert state in case accidental ETH is sent
        revert();
    }
}