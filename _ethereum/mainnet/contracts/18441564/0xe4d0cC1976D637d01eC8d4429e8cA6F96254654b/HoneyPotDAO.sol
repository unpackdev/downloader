// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./Address.sol";

contract HoneyPotDAO is Ownable {
    // Define events
    event ReceivedEther(address sender, uint256 amount);
    event DrainedEther(address to, uint256 amount);

    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

    function drain() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
        emit DrainedEther(owner(), balance);
    }
}
