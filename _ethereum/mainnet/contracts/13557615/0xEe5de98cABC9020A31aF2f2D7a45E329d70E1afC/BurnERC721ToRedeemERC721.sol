// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IERC721.sol";
import "./Reentrancy.sol";
import "./ITreasuryConfig.sol";
import "./IMirrorTreasury.sol";

/**
 * @title BurnERC721ToRedeemERC721
 * @author MirrorXYZ
 * Allows burning an "option" token in exchange for redeeming another transferrable
 * token.
 */
contract BurnERC721ToRedeemERC721 is Reentrancy {
    // ============ Immutable Storage ============

    // The recipient of the sales in ETH.
    address public immutable fundingRecipient;
    // The ERC721 token that is being burned by the redeemer.
    address public immutable burnToken;
    // The owner of the ERC721 token that is being redeemed.
    address public immutable nftSender;
    // The price of the token being redeemed.
    uint256 public immutable price;
    // The address of the Mirror treasury config, for getting the treasury address.
    address public immutable treasuryConfig;
    // The address of the redeemable token.
    address public immutable nft;
    // The token ID of the first token that's being redeemed.
    uint256 public immutable startingId;
    // The total number of tokens that are being redeemed.
    uint256 public immutable totalTokens;
    // The timestamp past which tokens cannot be redeemed.
    uint256 public immutable endTime;

    // ============ Mutable Storage ============

    uint256 public tokenCounter;

    // ============ Events ============

    event Redeem(address indexed redeemer, uint256 tokenCounter);

    // ============ Constructor ============

    constructor(
        address burnToken_,
        address nftSender_,
        address nft_,
        uint256 price_,
        address fundingRecipient_,
        address treasuryConfig_,
        uint256 startingId_,
        uint256 totalTokens_,
        uint256 redemptionDurationSeconds
    ) {
        burnToken = burnToken_;
        price = price_;
        treasuryConfig = treasuryConfig_;
        fundingRecipient = fundingRecipient_;
        nftSender = nftSender_;
        nft = nft_;
        startingId = startingId_;
        totalTokens = totalTokens_ + startingId_;

        endTime = block.timestamp + redemptionDurationSeconds;
    }

    // ============ Redeem Method ============

    /**
     * Allows the sender to burn some quantity of options in order
     * to redeem the same quantity of tokens, provided enough funds have
     * been transferred.
     */
    function redeem(uint256 burnableId) public payable nonReentrant {
        require(block.timestamp <= endTime, "Redemption period over");
        // Require that ETH has been sent.
        require(msg.value >= price, "Insufficient funds sent");
        // Burn the sender's ERC721 token.
        IERC721Burnable(burnToken).burn(burnableId);
        // Set the counter
        uint256 counter_ = startingId + tokenCounter;
        // Transfer the tokens to the user after burn.
        IERC721(nft).transferFrom(nftSender, msg.sender, counter_);
        // Increment the token counter.
        tokenCounter += 1;
        // Check that we haven't gone over the number of total tokens.
        require(tokenCounter <= totalTokens, "Token counter is out of range");

        emit Redeem(msg.sender, tokenCounter);
    }

    // ============ Withdraw Methods ============

    /**
     * @notice Withdraws funds on the current proxy to the operator,
     * and transfer fee to treasury.
     */
    function withdraw() external nonReentrant {
        uint256 feePercentage = 250;

        uint256 fee = feeAmount(address(this).balance, feePercentage);

        IMirrorTreasury(ITreasuryConfig(treasuryConfig).treasury()).contribute{
            value: fee
        }(fee);

        // transfer the remaining available balance to the operator.
        _send(payable(fundingRecipient), address(this).balance);
    }

    function feeAmount(uint256 amount, uint256 fee)
        public
        pure
        returns (uint256)
    {
        return (amount * fee) / 10000;
    }

    // ============ Internal Methods ============

    function _send(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "recipient reverted");
    }
}
