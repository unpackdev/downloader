// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.0;



// File: Ether.sol

contract Ether{

    function sendViaCall(address payable _to) public payable {
        (bool sent, bytes memory data) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

}
