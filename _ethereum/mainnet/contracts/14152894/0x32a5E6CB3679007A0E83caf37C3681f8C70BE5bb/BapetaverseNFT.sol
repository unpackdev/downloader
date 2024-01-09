// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract BapetaverseNFT {
    function mint(address payable recipient) payable external {
        recipient.transfer(msg.value);
    }
}