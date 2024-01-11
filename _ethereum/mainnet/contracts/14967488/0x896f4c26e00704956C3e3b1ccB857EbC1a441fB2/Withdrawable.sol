// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

// withdraw for owner
contract Withdrawable is Ownable {
    constructor() {}

    // withdraw all 
    function withdrawAll() external onlyOwner  {
        require(address(this).balance > 0, "Withdraw: No amount");
        payable(msg.sender).transfer(address(this).balance);
    }

}