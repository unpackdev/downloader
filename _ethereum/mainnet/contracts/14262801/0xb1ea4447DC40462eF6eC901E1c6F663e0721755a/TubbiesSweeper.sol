// SPDX-License-Identifier: GPL-3.0

import "./ITubbies.sol";

pragma solidity ^0.8.0;

 contract TubbiesSweeper {

     address constant public sweepingAddress = 0xa22f4c8E89070Ab2fa3EC5975DBcE143D8924Cd0;

    function sweep(address tubbiesContract) public {
        ITubbies tubbies = ITubbies(tubbiesContract);
        tubbies.mintFromSale{value: 0.5 ether}(5);
    }

    function getBalance() public view returns (uint256) {
      return address(this).balance;
    }

    function getFunds() payable external {

    }

    function transferOut(uint256[] memory tokenIds, address tubbiesContract) external {
        for (uint256 i=0; i < tokenIds.length; i++) {
             ITubbies tubbies = ITubbies(tubbiesContract);
            tubbies.transferFrom(address(this), sweepingAddress, tokenIds[i]);
        }
    }

    function withdraw() public {
        uint balance = address(this).balance;
        payable(sweepingAddress).transfer(balance);
    }
}
