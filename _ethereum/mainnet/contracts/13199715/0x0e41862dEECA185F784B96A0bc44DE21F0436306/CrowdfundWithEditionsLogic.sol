// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./CrowdfundWithEditionsStorage.sol";
import "./ERC20.sol";
import "./ICrowdfundWithEditions.sol";
import "./ITreasuryConfig.sol";

/**
 * @title CrowdfundWithEditionsLogic
 * @author MirrorXYZ
 *
 * Crowdfund the creation of NFTs by issuing ERC20 tokens that
 * can be redeemed for the underlying value of the NFT once sold.
 */
contract CrowdfundWithEditionsLogic is CrowdfundWithEditionsStorage, ERC20 {
    // ============ Events ============

    event ReceivedERC721(uint256 tokenId, address sender);
    event Contribution(address contributor, uint256 amount);
    event ContributionForEdition(
        address contributor,
        uint256 amount,
        uint256 editionId,
        uint256 tokenId
    );

    event FundingClosed(uint256 amountRaised, uint256 creatorAllocation);
    event BidAccepted(uint256 amount);
    event Redeemed(address contributor, uint256 amount);
    event Withdrawal(uint256 amount, uint256 fee);

    // ============ Modifiers ============

    /**
     * @dev Modifier to check whether the `msg.sender` is the operator.
     * If it is, it will run the function. Otherwise, it will revert.
     */
    modifier onlyOperator() {
        require(msg.sender == operator);
        _;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(reentrancy_status != REENTRANCY_ENTERED, "Reentrant call");

        // Any calls to nonReentrant after this point will fail
        reentrancy_status = REENTRANCY_ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        reentrancy_status = REENTRANCY_NOT_ENTERED;
    }

    // ============ Crowdfunding Methods ============

    /**
     * @notice Mints tokens for the sender propotional to the
     *  amount of ETH sent in the transaction.
     * @dev Emits the Contribution event.
     */
    function contribute(
        address payable backer,
        uint256 editionId,
        uint256 amount
    ) external payable nonReentrant {
        _contribute(backer, editionId, amount);
    }

    /**
     * @notice Burns the sender's tokens and redeems underlying ETH.
     * @dev Emits the Redeemed event.
     */
    function redeem(uint256 tokenAmount) external nonReentrant {
        // Prevent backers from accidently redeeming when balance is 0.
        require(
            address(this).balance > 0,
            "Crowdfund: No ETH available to redeem"
        );
        // Check
        require(
            balanceOf[msg.sender] >= tokenAmount,
            "Crowdfund: Insufficient balance"
        );
        require(status == Status.TRADING, "Crowdfund: Funding must be trading");
        // Effect
        uint256 redeemable = redeemableFromTokens(tokenAmount);
        _burn(msg.sender, tokenAmount);
        // Safe version of transfer.
        sendValue(payable(msg.sender), redeemable);
        emit Redeemed(msg.sender, redeemable);
    }

    /**
     * @notice Returns the amount of ETH that is redeemable for tokenAmount.
     */
    function redeemableFromTokens(uint256 tokenAmount)
        public
        view
        returns (uint256)
    {
        return (tokenAmount * address(this).balance) / totalSupply;
    }

    function valueToTokens(uint256 value) public pure returns (uint256 tokens) {
        tokens = value * TOKEN_SCALE;
    }

    function tokensToValue(uint256 tokenAmount)
        internal
        pure
        returns (uint256 value)
    {
        value = tokenAmount / TOKEN_SCALE;
    }

    // ============ Operator Methods ============

    /**
     * @notice Transfers all funds to operator, and mints tokens for the operator.
     *  Updates status to TRADING.
     * @dev Emits the FundingClosed event.
     */
    function closeFunding() external onlyOperator nonReentrant {
        require(status == Status.FUNDING, "Crowdfund: Funding must be open");
        // Close funding status, move to tradable.
        status = Status.TRADING;
        // Mint the operator a percent of the total supply.
        uint256 operatorTokens = (operatorPercent * totalSupply) /
            (100 - operatorPercent);
        _mint(operator, operatorTokens);
        // Announce that funding has been closed.
        emit FundingClosed(address(this).balance, operatorTokens);

        _withdraw();
    }

    /**
     * @notice Operator can change the funding recipient.
     */
    function changeFundingRecipient(address payable newFundingRecipient)
        public
        onlyOperator
    {
        fundingRecipient = newFundingRecipient;
    }

    function withdraw() public {
        _withdraw();
    }

    function computeFee(uint256 amount, uint256 feePercentage_)
        public
        pure
        returns (uint256 fee)
    {
        fee = (feePercentage_ * amount) / (100 * 100);
    }

    // ============ Utility Methods ============

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    // ============ Edition Methods ============

    function buyEdition(
        uint256 amount,
        uint256 editionId,
        address recipient
    ) internal returns (uint256) {
        // Check that the sender is paying the correct amount.
        require(
            amount >= ICrowdfundWithEditions(editions).editionPrice(editionId),
            "Unable purchase edition with available amount"
        );
        // We don't need to transfer the value to the NFT contract here,
        // since that contract trusts this one to check before minting.
        // I.E. this contract has minting privileges.
        return
            ICrowdfundWithEditions(editions).buyEdition(editionId, recipient);
    }

    // ============ Internal Methods  ============
    function _contribute(
        address payable backer,
        uint256 editionId,
        uint256 amount
    ) private {
        require(status == Status.FUNDING, "Crowdfund: Funding must be open");
        require(amount == msg.value, "Crowdfund: Amount is not value sent");
        // This first case is the happy path, so we will keep it efficient.
        // The balance, which includes the current contribution, is less than or equal to cap.
        if (address(this).balance <= fundingCap) {
            // Mint equity for the contributor.
            _mint(backer, valueToTokens(amount));

            // Editions start at 1, so a "0" edition means the user wants to contribute without
            // purchasing a token.
            if (editionId > 0) {
                emit ContributionForEdition(
                    backer,
                    amount,
                    editionId,
                    buyEdition(amount, editionId, backer)
                );
            } else {
                emit Contribution(backer, amount);
            }
        } else {
            // Compute the balance of the crowdfund before the contribution was made.
            uint256 startAmount = address(this).balance - amount;
            // If that amount was already greater than the funding cap, then we should revert immediately.
            require(
                startAmount < fundingCap,
                "Crowdfund: Funding cap already reached"
            );
            // Otherwise, the contribution helped us reach the funding cap. We should
            // take what we can until the funding cap is reached, and refund the rest.
            uint256 eligibleAmount = fundingCap - startAmount;
            // Otherwise, we process the contribution as if it were the minimal amount.
            _mint(backer, valueToTokens(eligibleAmount));

            if (editionId > 0) {
                emit ContributionForEdition(
                    backer,
                    eligibleAmount,
                    editionId,
                    // Attempt to purchase edition with eligible amount.
                    buyEdition(eligibleAmount, editionId, backer)
                );
            } else {
                emit Contribution(backer, eligibleAmount);
            }
            // Refund the sender with their contribution (e.g. 2.5 minus the diff - e.g. 1.5 = 1 ETH)
            sendValue(backer, amount - eligibleAmount);
        }
    }

    function _withdraw() internal {
        uint256 fee = feePercentage;

        emit Withdrawal(
            address(this).balance,
            computeFee(address(this).balance, fee)
        );

        // Transfer the fee to the treasury.
        sendValue(
            ITreasuryConfig(treasuryConfig).treasury(),
            computeFee(address(this).balance, fee)
        );
        // Transfer available balance to the fundingRecipient.
        sendValue(fundingRecipient, address(this).balance);
    }
}
