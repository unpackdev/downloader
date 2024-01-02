// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";

contract NpPublicCrowdsale is Crowdsale, TimedCrowdsale {
    using SafeERC20 for IERC20;

    uint public hardCap;
    uint public individualCap;

    constructor(
        uint hardCap_,
        uint individualCap_,
        uint numerator_,
        uint denominator_,
        address wallet_,
        IERC20 subject_,
        IERC20 token_,
        uint openingTime,
        uint closingTime
    ) Crowdsale(numerator_, denominator_, wallet_, subject_, token_) TimedCrowdsale(openingTime, closingTime) {
        hardCap = hardCap_;
        individualCap = individualCap_;
    }

    function setCap(uint hardCap_, uint individualCap_) external onlyOwner {
        hardCap = hardCap_;
        individualCap = individualCap_;
    }

    function getPurchasableAmount(address user, uint amount) public view returns (uint) {
        uint currentPurchase = purchasedAddresses[user];
        uint totalDesiredPurchase = currentPurchase + amount;
        if (totalDesiredPurchase > individualCap) {
            amount = individualCap - currentPurchase;
        }
        uint totalAfterPurchase = subjectRaised + amount;
        if (totalAfterPurchase > hardCap) {
            amount = hardCap - subjectRaised;
        }
        return amount;
    }

    function buyTokens(uint amount) external onlyWhileOpen nonReentrant {
        amount = getPurchasableAmount(msg.sender, amount);
        require(amount > 0, "PublicCrowdsale: purchasable amount is 0");

        subject.safeTransferFrom(msg.sender, wallet, amount);

        // update state
        subjectRaised += amount;
        purchasedAddresses[msg.sender] += amount;

        emit TokenPurchased(msg.sender, amount);
    }

    function claim() external nonReentrant {
        require(hasClosed(), "PublicCrowdsale: not closed");
        require(!claimed[msg.sender], "PublicCrowdsale: already claimed");

        uint tokenAmount = getTokenAmount(purchasedAddresses[msg.sender]);
        require(tokenAmount > 0, "PublicCrowdsale: not purchased");

        require(address(token) != address(0), "PublicCrowdsale: token not set");
        claimed[msg.sender] = true;
        token.safeTransfer(msg.sender, tokenAmount);

        emit TokenClaimed(msg.sender, tokenAmount);
    }
}
