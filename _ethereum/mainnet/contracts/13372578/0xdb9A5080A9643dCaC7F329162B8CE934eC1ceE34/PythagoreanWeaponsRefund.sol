// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

contract PythagoreanWeaponsRefund is Ownable, ReentrancyGuard {

    mapping(address => uint256) public refundRecipients;
    uint256 endOfRefundPeriod;

    function setRefundRecipients(address[] memory addresses, uint256[] memory refunds) external onlyOwner {
        require(addresses.length == refunds.length, "Huh?");
        endOfRefundPeriod = block.timestamp + (30 * 24 * 60 * 60);
        for (uint256 i; i < addresses.length; i++) {
            refundRecipients[addresses[i]] = refunds[i];
        }
    }

    function refund() external nonReentrant {
        require(refundRecipients[msg.sender] > 0, "No refund");
        uint256 _refund = refundRecipients[msg.sender];
        refundRecipients[msg.sender] = 0;
        Address.sendValue(payable(msg.sender), _refund);
    }

    function salvageETH() external onlyOwner {
        require(block.timestamp > endOfRefundPeriod, "Can't yet");
        require(address(this).balance > 0, "No");
        Address.sendValue(payable(owner()), address(this).balance);
    }

    receive() external payable {}
}
