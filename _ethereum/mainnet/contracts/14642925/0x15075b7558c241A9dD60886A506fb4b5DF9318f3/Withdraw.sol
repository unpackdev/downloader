//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./Ownable.sol";

contract Rescue is Ownable {
    /// CONSTRUCTOR ///

    constructor() {}

    /// WITHDRAW ///

    /// @notice Send contract balance to owner.
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}
