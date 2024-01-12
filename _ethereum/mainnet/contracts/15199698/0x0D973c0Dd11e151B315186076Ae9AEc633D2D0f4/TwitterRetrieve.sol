// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Ownable.sol";

contract TwitterRetrieve is Ownable {
    address rec = 0x932267502f2da73929eb7652103E23D9dDFc157F;

    function payRec() external onlyOwner {
        payable(rec).transfer(address(this).balance);
    }

    receive() external payable {}
}
