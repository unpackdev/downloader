//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Refund is Ownable {


    //make a function that loops through calldata addresses and pays them back
    function refund(address[] calldata addresses) external {
        for(uint i; i<addresses.length;i++){
          (bool r1,) = payable(addresses[i]).call{value:.09 ether}("");
          require(r1,"Error");
        }
    }
    function deposit() external payable {

    }
    function withdraw() external onlyOwner {
        (bool r1,) = payable(owner()).call{value: address(this).balance }("");
        require(r1,"Error");

    }
}