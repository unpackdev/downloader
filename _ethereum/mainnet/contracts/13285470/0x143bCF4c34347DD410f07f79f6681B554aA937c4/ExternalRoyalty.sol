// SPDX-License-Identifier: UNLICENSED

// Code by zipzinger and cmtzco
// DEFIBOYS
// defiboys.com

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

import "./Nft.sol";

contract ExternalRoyalty is Ownable {
    using Address for address payable;
    address payable public nftContractAddress;

    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    constructor(address payable _nftContractAddress) {
        nftContractAddress = _nftContractAddress;
    }

    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    function release() public virtual onlyOwner {
        uint256 totalReceived = address(this).balance;
        uint256 royaltyCount = Nft(nftContractAddress).royaltyCount();

        uint256 id;
        for (id = 1; id <= royaltyCount; id++) {
            address payable royaltyRecipient = Nft(nftContractAddress)
                .royaltyRecipients(id);
            uint256 royaltyPercent = Nft(nftContractAddress).royaltyPercents(
                id
            );
            uint256 payment = SafeMath.div(
                SafeMath.mul(totalReceived, royaltyPercent),
                10000
            );
            Address.sendValue(royaltyRecipient, payment);
            emit PaymentReleased(royaltyRecipient, payment);
        }
    }

    function collectDust() external onlyOwner {
        msg.sender.call{value: address(this).balance}("");
    }
}
