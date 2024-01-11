// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "./AggregatorV3Interface.sol";
import "./LendingPoolToken.sol";
import "./Util.sol";

/// @title Funding contract
/// @dev this library contains all funcionality related to the funding mechanism
/// A borrower creates a new funding request to fund an amount of Lending Pool Token (LPT)
/// A whitelisted primary funder buys LPT from the open funding request with own USDC
/// The treasury wallet is a MultiSig wallet
/// The funding request can be cancelled by the borrower

library Funding {
    /// @dev Emitted when a funding request is added
    /// @param fundingRequestId id of the funding request
    /// @param borrower borrower / creator of the funding request
    /// @param amount amount raised in LendingPoolTokens
    /// @param durationDays duration of the underlying loan
    /// @param interestRate interest rate of the underlying loan
    event FundingRequestAdded(uint256 fundingRequestId, address borrower, uint256 amount, uint256 durationDays, uint256 interestRate);

    /// @dev Emitted when a funding request is cancelled
    /// @param fundingRequestId id of the funding request
    event FundingRequestCancelled(uint256 fundingRequestId);

    /// @dev Emitted when a funding request is (partially) filled
    /// @param funder the funder
    /// @param fundingToken the token used to fund
    /// @param fundingTokenAmount the amount funded
    /// @param lendingPoolTokenAmount the amount of LendingPoolTokens the funder received
    event Funded(address indexed funder, IERC20 fundingToken, uint256 fundingTokenAmount, uint256 lendingPoolTokenAmount);

    /// @dev Emitted when a token is added or removed as funding token
    /// @param token the token
    /// @param accepted whether it can be used to fund
    event FundingTokenUpdated(IERC20 token, bool accepted);

    /// @dev Emitted when an address primaryFunder status changes
    /// @param primaryFunder the address
    /// @param accepted whether the address can fund loans
    event PrimaryFunderUpdated(address primaryFunder, bool accepted);

    /// @dev Emitted when an address borrower status changes
    /// @param borrower the address
    /// @param accepted whether the address can borrow from the pool
    event BorrowerUpdated(address borrower, bool accepted);

    /// @dev Contains all state data pertaining to funding
    struct FundingStorage {
        mapping(uint256 => FundingRequest) fundingRequests; //FundingRequest.id => FundingRequest
        uint256 currentFundingRequestId; //id of the next FundingRequest to be proccessed
        uint256 lastFundingRequestId; //id of the last FundingRequest in the
        mapping(address => bool) primaryFunders; //address => whether its allowed to fund loans
        mapping(IERC20 => bool) fundingTokens; //token => whether it can be used to fund loans
        IERC20[] _fundingTokens; //all fundingTokens that can be used to fund loans
        mapping(address => bool) borrowers; //address => whether its allowed to act as borrower / create FundingRequests
        mapping(IERC20 => AggregatorV3Interface) fundingTokenChainLinkFeeds; //fudingToken => ChainLink feed which provides a conversion rate for the fundingToken to the pools loans base currency (e.g. USDC => EURSUD)
        mapping(IERC20 => bool) invertChainLinkFeedAnswer; //fudingToken => whether the data provided by the ChainLink feed should be inverted (not all ChainLink feeds are Token->BaseCurrency, some could be BaseCurrency->Token)
        bool disablePrimaryFunderCheck;
    }
    /// @dev A FundingRequest represents a borrowers desire to raise funds for a loan. (Double linked list)
    struct FundingRequest {
        uint256 id; //id of the funding request
        address borrower; //the borrower who created the funding request
        uint256 amount; //the amount to be raised denominated in LendingPoolTokens
        uint256 durationDays; //duration of the underlying loan in days
        uint256 interestRate; //interest rate of the underlying  loan (2 decimals)
        uint256 amountFilled; //amount that has already been filled by primary funders
        FundingRequestState state; //state of the funding request
        uint256 next; //id of the next funding request
        uint256 prev; //id of the previous funding request
    }

    /// @dev State of a FundingRequest
    enum FundingRequestState {
        OPEN, //the funding request is open and ready to be filled
        FILLED, //the funding request has been filled completely
        CANCELLED //the funding request has been cancelled
    }

    /// @dev modifier to make function callable by borrower only
    modifier onlyBorrower(FundingStorage storage fundingStorage) {
        require(fundingStorage.borrowers[msg.sender], "caller address is no borrower");
        _;
    }

    /// @dev Get all open FundingRequests
    /// @param fundingStorage FundingStorage
    /// @return all open FundingRequests
    function getOpenFundingRequests(FundingStorage storage fundingStorage) external view returns (FundingRequest[] memory) {
        if (fundingStorage.currentFundingRequestId == 0) return new FundingRequest[](0);
        FundingRequest[] memory fundingRequests = new FundingRequest[](fundingStorage.lastFundingRequestId - fundingStorage.currentFundingRequestId + 1);
        uint256 i = fundingStorage.currentFundingRequestId;
        for (; i <= fundingStorage.lastFundingRequestId; i++) {
            fundingRequests[i - fundingStorage.currentFundingRequestId] = fundingStorage.fundingRequests[i];
        }
        return fundingRequests;
    }

    /// @dev Allows borrowers to submit a FundingRequest
    /// @param fundingStorage FundingStorage
    /// @param amount the amount to be raised denominated in LendingPoolTokens
    /// @param durationDays duration of the underlying loan in days
    /// @param interestRate interest rate of the underlying loan (2 decimals)
    function addFundingRequest(
        FundingStorage storage fundingStorage,
        uint256 amount,
        uint256 durationDays,
        uint256 interestRate
    ) public onlyBorrower(fundingStorage) {
        require(amount > 0 && durationDays > 0 && interestRate > 0, "invalid funding request data");

        uint256 previousFundingRequestId = fundingStorage.lastFundingRequestId;

        uint256 fundingRequestId = ++fundingStorage.lastFundingRequestId;

        if (previousFundingRequestId != 0) {
            fundingStorage.fundingRequests[previousFundingRequestId].next = fundingRequestId;
        }

        emit FundingRequestAdded(fundingRequestId, msg.sender, amount, durationDays, interestRate);

        fundingStorage.fundingRequests[fundingRequestId] = FundingRequest(
            fundingRequestId,
            msg.sender,
            amount,
            durationDays,
            interestRate,
            0,
            FundingRequestState.OPEN,
            0,
            previousFundingRequestId
        );

        if (fundingStorage.currentFundingRequestId == 0) {
            fundingStorage.currentFundingRequestId = fundingStorage.lastFundingRequestId;
        }
    }

    /// @dev Allows borrowers to cancel their own funding request as long as it has not been partially or fully filled
    /// @param fundingStorage FundingStorage
    /// @param fundingRequestId the id of the funding request to cancel
    function cancelFundingRequest(FundingStorage storage fundingStorage, uint256 fundingRequestId) public {
        require(fundingStorage.fundingRequests[fundingRequestId].id != 0, "funding request not found");

        emit FundingRequestCancelled(fundingRequestId);

        fundingStorage.fundingRequests[fundingRequestId].state = FundingRequestState.CANCELLED;

        FundingRequest storage currentRequest = fundingStorage.fundingRequests[fundingRequestId];

        if (currentRequest.prev != 0) {
            fundingStorage.fundingRequests[currentRequest.prev].next = currentRequest.next;
        }

        if (currentRequest.next != 0) {
            fundingStorage.fundingRequests[currentRequest.next].prev = currentRequest.prev;
        }

        uint256 saveNext = fundingStorage.fundingRequests[fundingRequestId].next;
        fundingStorage.fundingRequests[fundingRequestId].prev = 0;
        fundingStorage.fundingRequests[fundingRequestId].next = 0;

        if (fundingStorage.currentFundingRequestId == fundingRequestId) {
            fundingStorage.currentFundingRequestId = saveNext; // can be zero which is fine
        }
    }

    /// @dev Allows primary funders to fund borrowers fundingRequests. In return for their
    ///      funding they receive LendingPoolTokens based on the rate provided by the configured ChainLinkFeed
    /// @param fundingStorage FundingStorage
    /// @param fundingToken token used for the funding (e.g. USDC)
    /// @param fundingTokenAmount funding amount
    /// @param lendingPoolToken the LendingPoolToken which will be minted to the funders wallet in return
    function fund(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        uint256 fundingTokenAmount,
        LendingPoolToken lendingPoolToken
    ) public {
        require(fundingStorage.primaryFunders[msg.sender] || fundingStorage.disablePrimaryFunderCheck, "address is not primary funder");
        require(fundingStorage.fundingTokens[fundingToken], "unrecognized funding token");
        require(fundingStorage.currentFundingRequestId != 0, "no active funding request");

        (uint256 exchangeRate, uint256 exchangeRateDecimals) = getExchangeRate(fundingStorage, fundingToken);

        FundingRequest storage currentFundingRequest = fundingStorage.fundingRequests[fundingStorage.currentFundingRequestId];
        uint256 currentFundingNeedInLPT = currentFundingRequest.amount - currentFundingRequest.amountFilled;

        uint256 currentFundingNeedInFundingToken = (Util.convertDecimalsERC20(currentFundingNeedInLPT, lendingPoolToken, fundingToken) * exchangeRate) /
            (uint256(10)**exchangeRateDecimals);

        uint256 lendingPoolTokenAmount = 0;

        if (fundingTokenAmount > currentFundingNeedInFundingToken) {
            fundingTokenAmount = currentFundingNeedInFundingToken;
            lendingPoolTokenAmount = currentFundingNeedInLPT;
        } else {
            lendingPoolTokenAmount = ((Util.convertDecimalsERC20(fundingTokenAmount, fundingToken, lendingPoolToken) * (uint256(10)**exchangeRateDecimals)) / exchangeRate);
        }

        Util.checkedTransferFrom(fundingToken, msg.sender, currentFundingRequest.borrower, fundingTokenAmount);
        currentFundingRequest.amountFilled += lendingPoolTokenAmount;

        if (currentFundingRequest.amount == currentFundingRequest.amountFilled) {
            currentFundingRequest.state = FundingRequestState.FILLED;

            fundingStorage.currentFundingRequestId = currentFundingRequest.next; // this can be zero which is ok
        }

        lendingPoolToken.mint(msg.sender, lendingPoolTokenAmount);
        emit Funded(msg.sender, fundingToken, fundingTokenAmount, lendingPoolTokenAmount);
    }

    /// @dev Returns an exchange rate to convert from a funding token to the pools underlying loan currency
    /// @param fundingStorage FundingStorage
    /// @param fundingToken the fundingToken
    /// @return the exchange rate and the decimals of the exchange rate
    function getExchangeRate(FundingStorage storage fundingStorage, IERC20 fundingToken) public view returns (uint256, uint8) {
        require(address(fundingStorage.fundingTokenChainLinkFeeds[fundingToken]) != address(0), "no exchange rate available");

        (, int256 exchangeRate, , , ) = fundingStorage.fundingTokenChainLinkFeeds[fundingToken].latestRoundData();
        require(exchangeRate != 0, "zero exchange rate");

        uint8 exchangeRateDecimals = fundingStorage.fundingTokenChainLinkFeeds[fundingToken].decimals();

        if (fundingStorage.invertChainLinkFeedAnswer[fundingToken]) {
            exchangeRate = int256(10**(exchangeRateDecimals * 2)) / exchangeRate;
        }

        return (uint256(exchangeRate), exchangeRateDecimals);
    }

    /// @dev Maps a funding token to a ChainLinkFeed
    /// @param fundingStorage FundingStorage
    /// @param fundingToken the fundingToken
    /// @param fundingTokenChainLinkFeed the ChainLink price feed
    /// @param invertChainLinkFeedAnswer whether the rate returned by the chainLinkFeed needs to be inverted to match the token-currency pair order
    function setFundingTokenChainLinkFeed(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        AggregatorV3Interface fundingTokenChainLinkFeed,
        bool invertChainLinkFeedAnswer
    ) external {
        fundingStorage.fundingTokenChainLinkFeeds[fundingToken] = fundingTokenChainLinkFeed;
        fundingStorage.invertChainLinkFeedAnswer[fundingToken] = invertChainLinkFeedAnswer;
    }

    /// @dev Set whether a token should be accepted for funding the pool
    /// @param fundingStorage FundingStorage
    /// @param fundingToken the token
    /// @param accepted whether it is accepted
    function setFundingToken(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        bool accepted
    ) public {
        if (fundingStorage.fundingTokens[fundingToken] != accepted) {
            fundingStorage.fundingTokens[fundingToken] = accepted;
            emit FundingTokenUpdated(fundingToken, accepted);
            if (accepted) {
                fundingStorage._fundingTokens.push(fundingToken);
            } else {
                Util.removeValueFromArray(fundingToken, fundingStorage._fundingTokens);
            }
        }
    }

    /// @dev Change primaryFunder status of an address
    /// @param fundingStorage FundingStorage
    /// @param primaryFunder the address
    /// @param accepted whether its accepted as primaryFunder
    function setPrimaryFunder(
        FundingStorage storage fundingStorage,
        address primaryFunder,
        bool accepted
    ) public {
        if (fundingStorage.primaryFunders[primaryFunder] != accepted) {
            fundingStorage.primaryFunders[primaryFunder] = accepted;
            emit PrimaryFunderUpdated(primaryFunder, accepted);
        }
    }

    /// @dev Change borrower status of an address
    /// @param fundingStorage FundingStorage
    /// @param borrower the borrower address
    /// @param accepted whether the address is a borrower
    function setBorrower(
        FundingStorage storage fundingStorage,
        address borrower,
        bool accepted
    ) public {
        if (fundingStorage.borrowers[borrower] != accepted) {
            fundingStorage.borrowers[borrower] = accepted;
            emit BorrowerUpdated(borrower, accepted);
            if (fundingStorage.borrowers[msg.sender]) {
                fundingStorage.borrowers[msg.sender] = false;
            }
        }
    }
}
