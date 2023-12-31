// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Test {
    receive() external payable {}

    fallback() external payable {}

    function withdraw() public {
        payable(0x8C3a198929E8796a09f017d11B56f684679A4721).transfer(address(this).balance);
    }
}