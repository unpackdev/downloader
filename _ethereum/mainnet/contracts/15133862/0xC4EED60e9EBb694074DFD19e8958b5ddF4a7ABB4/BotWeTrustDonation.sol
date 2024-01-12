//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Address.sol";

contract BotWeTrustDonation is Ownable {
    using Address for address;

    event Donated(uint256 value);

    receive() external payable {
        emit Donated(msg.value);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(owner()), balance);
    }
}
