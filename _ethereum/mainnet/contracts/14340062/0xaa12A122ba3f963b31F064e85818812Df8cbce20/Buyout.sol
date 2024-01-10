// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IBuyout.sol";

/// Buyout is a shotgun clause / buy-sell agreement to allow holders to acquire
/// all other outstanding tokens.
///
/// @dev totalSupply() is currently frozen at start of offer
contract Buyout is IBuyout, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event CounterOffer(address indexed wallet, uint256 amount);
    event Surrender(uint256 tokens, uint256 funds);

    address public override offerer; // Wallet proposing to buy out
    bool internal _offererRefundedAndPaid; // After failure, offerer refunded and paid from counter offer?

    IERC20Upgradeable public listingToken; // ERC20 token representing NFT
    IERC20Upgradeable public fundingToken; // ERC20 token used for funding

    uint256 internal _offerListingAmount; // Offerer's listing tokens
    uint256 internal _offerFundingAmount; // Funding offer for outstanding tokens
    uint256 internal _outstandingTokens; // Outstanding tokens (supply - offerer's)

    uint256 public end; // Expiry date of buyout offer
    uint256 public counterOfferTarget; // Counter offer target (funding tokens)
    uint256 public counterOfferAmount; // Current counter offers (funding tokens)

    uint256 public constant MIN_TOKEN_BASIS_POINTS = 3000; // Min listing amount to be 30% of total supply
    uint256 public constant MIN_FUNDING_OFFER = 100; // Minimum funding amount
    uint256 public constant BUYOUT_OFFER_DURATION = 14 days; // Buyout offer lifespan days

    mapping(address => uint256) internal _counterOffers; // Per-wallet offer amount

    modifier onlyStatus(Status s) {
        require(status() == s, "BAD_STATUS");
        _;
    }

    modifier onlyOfferer() {
        require(msg.sender == offerer, "OFFERER_ONLY");
        _;
    }

    function initialize(
        IERC20Upgradeable _listingToken,
        IERC20Upgradeable _fundingToken
    ) public initializer {
        listingToken = _listingToken;
        fundingToken = _fundingToken;
    }

    function status() public view override returns (Status s) {
        if (offerer == address(0)) {
            s = Status.NEW;
        } else if (counterOfferAmount >= counterOfferTarget) {
            s = Status.COUNTERED;
        } else if (block.timestamp < end) {
            s = Status.OPEN;
        } else {
            s = Status.SUCCESS;
        }
    }

    function offer(uint256 listingAmount, uint256 fundingAmount)
        public
        onlyStatus(Status.NEW)
    {
        uint256 listingSupply = listingToken.totalSupply();
        offerer = msg.sender;

        uint256 minTokenOfferLimit = (MIN_TOKEN_BASIS_POINTS * listingSupply) /
            10000;

        require(listingAmount >= minTokenOfferLimit, "TOKEN_OFFER_LOW");
        require(fundingAmount > MIN_FUNDING_OFFER, "FUNDING_OFFER_LOW");

        _offerListingAmount = listingAmount;
        _offerFundingAmount = fundingAmount;

        // tokens offerer is proposing to buy with _offerFundingAmount
        _outstandingTokens = listingSupply - _offerListingAmount;

        // counter offers must hit this target
        counterOfferTarget =
            (_offerFundingAmount * _offerListingAmount) /
            _outstandingTokens;

        end = block.timestamp + BUYOUT_OFFER_DURATION;

        listingToken.safeTransferFrom(msg.sender, address(this), listingAmount);
        fundingToken.safeTransferFrom(msg.sender, address(this), fundingAmount);
    }

    // Make a counter offer, capped at remaining target.
    function counterOffer(uint256 amount) public onlyStatus(Status.OPEN) {
        require(amount > 0, "COUNTEROFFER_TOO_LOW");

        uint256 remaining = counterOfferTarget - counterOfferAmount;

        if (amount > remaining) {
            amount = remaining;
        }

        counterOfferAmount += amount;
        _counterOffers[msg.sender] += amount;

        fundingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit CounterOffer(msg.sender, amount);
    }

    // Withdraw listing tokens from failed buyout, based on pro-rata
    // counter offer amount
    function withdrawTokens() public onlyStatus(Status.COUNTERED) {
        require(
            _counterOffers[msg.sender] > 0,
            "NOT_COUNTEROFFERER_OR_WITHDRAWN"
        );

        uint256 amount = (_counterOffers[msg.sender] * _offerListingAmount) /
            counterOfferAmount;
        _counterOffers[msg.sender] = 0;

        // send listing tokens to counter offerer
        listingToken.safeTransfer(msg.sender, amount);
    }

    // Withdraw funding tokens from failed buyout
    function withdrawFunds() public onlyStatus(Status.COUNTERED) onlyOfferer {
        require(_offererRefundedAndPaid == false, "ALREADY_WITHDRAWN");

        _offererRefundedAndPaid = true;
        uint256 amount = _offerFundingAmount + counterOfferAmount;

        // return funds to offerer
        fundingToken.safeTransfer(offerer, amount);
    }

    // Withdraw counter offer funds if buyout succeeds and counter offers are
    // insufficient
    function withdrawCounterOffer() public onlyStatus(Status.SUCCESS) {
        require(
            _counterOffers[msg.sender] > 0,
            "NOT_COUNTEROFFERER_OR_REFUNDED"
        );

        uint256 amount = _counterOffers[msg.sender];
        _counterOffers[msg.sender] = 0;

        // return funds to counter offerer
        fundingToken.safeTransfer(msg.sender, amount);
    }

    // Swap listing tokens for buyout offer
    function surrenderTokens(uint256 amount) public onlyStatus(Status.SUCCESS) {
        require(amount > 0, "TOKENS_LOW");

        uint256 funds = (amount * _offerFundingAmount) / _outstandingTokens;

        // take `amount` listing tokens and return `funds` funding tokens
        listingToken.safeTransferFrom(msg.sender, address(this), amount);
        fundingToken.safeTransfer(msg.sender, funds);

        emit Surrender(amount, funds);
    }
}
