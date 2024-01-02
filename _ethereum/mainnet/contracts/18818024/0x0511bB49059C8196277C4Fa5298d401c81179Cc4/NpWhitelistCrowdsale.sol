// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";

contract NpWhitelistCrowdsale is Crowdsale, TimedCrowdsale {
    using SafeERC20 for IERC20;

    bytes32 public merkleRoot;
    uint public hardCap;
    uint public individualCap;

    constructor(
        uint hardCap_,
        uint individualCap_,
        bytes32 merkleRoot_,
        uint numerator_,
        uint denominator_,
        address wallet_,
        IERC20 subject_,
        IERC20 token_,
        uint openingTime,
        uint closingTime
    ) Crowdsale(numerator_, denominator_, wallet_, subject_, token_) TimedCrowdsale(openingTime, closingTime) {
        merkleRoot = merkleRoot_;
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

    function setRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function buyTokens(uint amount, bytes32[] calldata merkleProof) external onlyWhileOpen nonReentrant {
        amount = getPurchasableAmount(msg.sender, amount);
        require(amount > 0, "WhitelistCrowdsale: invalid purchase amount");

        require(MerkleProof.verifyCalldata(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "WhitelistCrowdsale: invalid proof");

        subject.safeTransferFrom(msg.sender, wallet, amount);

        // update state
        subjectRaised += amount;
        purchasedAddresses[msg.sender] += amount;

        emit TokenPurchased(msg.sender, amount);
    }

    function claim() external nonReentrant {
        require(hasClosed(), "WhitelistCrowdsale: not closed");
        require(!claimed[msg.sender], "WhitelistCrowdsale: already claimed");

        uint tokenAmount = getTokenAmount(purchasedAddresses[msg.sender]);
        require(tokenAmount > 0, "WhitelistCrowdsale: not purchased");

        require(address(token) != address(0), "WhitelistCrowdsale: token not set");
        claimed[msg.sender] = true;
        token.safeTransfer(msg.sender, tokenAmount);

        emit TokenClaimed(msg.sender, tokenAmount);
    }
}
