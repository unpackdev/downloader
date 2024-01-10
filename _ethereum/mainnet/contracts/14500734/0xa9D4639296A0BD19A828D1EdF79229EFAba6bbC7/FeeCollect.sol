// SPDX-License-Identifier: AGPL-3.0-or-later



pragma solidity ^0.8.0;

import "./Ownable.sol";

contract FeeCollect is Ownable {
	
	function withdraw() external {
        uint256 balance = address(this).balance;
        (bool sent, ) = owner().call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
	
	fallback() external payable {}
    receive() external payable {}
}