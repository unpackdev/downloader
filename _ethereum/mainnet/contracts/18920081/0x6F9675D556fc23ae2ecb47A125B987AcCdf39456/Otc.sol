// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20Metadata.sol";
import "./EnumerableSet.sol";
import "./FixedPointMathLib.sol";

contract OneSeedOtc is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    event TradeOfferCreated(uint256 tradeId, address creator, address collateralToken, uint256 costPerToken, uint256 tokens);
    event TradeOfferCancelled(uint256 tradeId);
    event TradeOfferAccepted(uint256 tradeId, uint256 agreementId, address seller, address buyer);
    event AgreementFulfilled(uint256 agreementId);
    event Claimed(uint256 agreementId, address buyer, address collateralToken, uint256 amount, uint256 fee);
    event Expired(uint256 endTs);
    event EmergencyWithdrawlsEnabled(bool enabled);

    EnumerableSet.AddressSet private _supportToken;

    address public OTC_ADDRESS;
    uint256 public OTC_DENOMINATOR = 10 ** 18;

    address public FEE = 0x05226ca77b41b227D7a7bc6eBB700940b384b708;

    //Max and min costs to prevent over/under paying mistakes.
    uint256 public MAX_COST = 100 * 10**6; //Max of 100 U
    uint256 public MIN_COST = 0.1 * 10**6; //Min of 0.01 U

    uint256 public OFFERS_EXPIRED;
    bool public EMERGENCY_WITHDRAWL = false;
    bool public ACCEPTING_OFFERS_ENABLED = true;

    mapping(address => mapping(address => uint256)) public collateralDeposited;

    TradeOffer[] public tradeOffers;
    Agreement[] public agreements;

    struct TradeOffer {
        address creator;
        address collateralToken;
        uint256 tokens;
        uint256 costPerToken;
        uint256 tradeId;
        bool active;
    }

    struct Agreement {
        address seller;
        address buyer;
        address collateralToken;
        uint256 tokens;
        uint256 costPerToken;
        uint256 tradeId;
        bool active;
    }

    /// @notice Allows a seller to create a trade offer
    /// @dev Requires the seller to lock 25% of the total cost as collateral
    /// @param _costPerToken The cost per token in USD
    /// @param _tokens The number of tokens offered in the trade in an otc decimal format.
    /// @param _collateralToken The address of the token to use as collateral
    function createOffer(uint256 _costPerToken, uint256 _tokens, address _collateralToken) public nonReentrant {
        require(_tokens >= OTC_DENOMINATOR, "Must be gather than 1 token");

        require(OTC_ADDRESS != address(0), "OTC not set");
        require(_supportToken.contains(_collateralToken), "Not Supported");
        require(_costPerToken >= MIN_COST, "Below min cost");
        require(_costPerToken <= MAX_COST, "Above max cost");
        require(OFFERS_EXPIRED == 0 || OFFERS_EXPIRED > block.timestamp, "Offers not allowed");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWL, "Emergency withdrawl enabled");

        uint256 collateral = (FixedPointMathLib.mulDivUp(_costPerToken, _tokens, OTC_DENOMINATOR) * 25 / 100);

        collateralDeposited[_collateralToken][msg.sender] += collateral;

        IERC20(_collateralToken).transferFrom(msg.sender, address(this), collateral);

        TradeOffer memory newOffer = TradeOffer({
            creator: msg.sender,
            collateralToken: _collateralToken,
            tokens: _tokens,
            costPerToken: _costPerToken,
            tradeId: tradeOffers.length,
            active: true
        });

        tradeOffers.push(newOffer);

        emit TradeOfferCreated(newOffer.tradeId, msg.sender, _collateralToken, _costPerToken, _tokens);
    }

    /// @notice Allows the creator of a trade offer to cancel it
    /// @dev Returns the collateral locked by the creator and marks the offer as inactive
    /// @param tradeId The ID of the trade offer to cancel
    function cancelOffer(uint256 tradeId) public nonReentrant {
        TradeOffer storage offer = tradeOffers[tradeId];
        require(offer.active, "Offer accepted or cancelled");
        require(offer.creator == msg.sender, "Not your offer");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWL, "Emergency withdrawl enabled");

        uint256 collateral = FixedPointMathLib.mulDivUp(offer.costPerToken, offer.tokens, OTC_DENOMINATOR) * 25 / 100;

        offer.active = false;

        collateralDeposited[offer.collateralToken][msg.sender] -= collateral;

        IERC20(offer.collateralToken).transfer(msg.sender, collateral);

        emit TradeOfferCancelled(tradeId);
    }

    /// @notice Allows a user to accept an existing trade offer
    /// @dev The buyer pays the full cost of the tokens and the offer is marked as inactive
    /// @param tradeId The ID of the trade offer to accept
    function acceptOffer(uint256 tradeId) public nonReentrant {
        TradeOffer storage offer = tradeOffers[tradeId];
        require(offer.active, "Offer accepted or cancelled");
        require(msg.sender != offer.creator, "Can't accept own offer");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWL, "Emergency withdrawl enabled");
        require(OFFERS_EXPIRED == 0 || OFFERS_EXPIRED > block.timestamp, "Offers have expired");
        require(ACCEPTING_OFFERS_ENABLED, "Accepting offers has been disabled");

        uint256 cost = FixedPointMathLib.mulDivUp(offer.costPerToken, offer.tokens, OTC_DENOMINATOR);

        collateralDeposited[offer.collateralToken][msg.sender] += cost;

        IERC20(offer.collateralToken).transferFrom(msg.sender, address(this), cost);

        offer.active = false;

        Agreement memory newAgreement = Agreement({
            seller: offer.creator,
            buyer: msg.sender,
            collateralToken: offer.collateralToken,
            tokens: offer.tokens,
            costPerToken: offer.costPerToken,
            tradeId: agreements.length,
            active: true
        });

        agreements.push(newAgreement);

        emit TradeOfferAccepted(tradeId, newAgreement.tradeId, newAgreement.seller, newAgreement.buyer);
    }

    /// @notice Allows the seller of an agreement to fulfill it
    /// @dev The seller receives the payment minus a 5% fee, and the collateral is returned
    /// @param agreementId The ID of the agreement to fulfill
    function fulfilOffer(uint256 agreementId) public nonReentrant {
        Agreement storage agreement = agreements[agreementId];
        require(agreement.active, "Not active");
        require(OFFERS_EXPIRED > block.timestamp, "Agreement expired yet");
        require(msg.sender == agreement.seller, "Not seller");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWL, "Emergency withdrawl enabled");

        agreement.active = false;

        uint256 otcToSend = agreement.tokens;

        uint256 otcFee = otcToSend * 5 / 100;

        IERC20(OTC_ADDRESS).transferFrom(msg.sender, agreement.buyer, otcToSend - otcFee);

        IERC20(OTC_ADDRESS).transferFrom(msg.sender, address(this), otcFee);

        IERC20(OTC_ADDRESS).transfer(FEE, otcFee);

        uint256 cost = FixedPointMathLib.mulDivUp(agreement.costPerToken, agreement.tokens, OTC_DENOMINATOR);
        uint256 fee = cost * 5 / 100;

        collateralDeposited[agreement.collateralToken][agreement.buyer] -= cost;

        IERC20(agreement.collateralToken).transfer(msg.sender, cost - fee);

        IERC20(agreement.collateralToken).transfer(FEE, fee);

        //Return collateral.
        uint256 collateral = (cost * 25 / 100);

        collateralDeposited[agreement.collateralToken][msg.sender] -= collateral;

        IERC20(agreement.collateralToken).transfer(msg.sender, collateral);

        emit AgreementFulfilled(agreementId);
    }

    /// @notice Allows the buyer of an agreement to claim the collateral if the agreement has not been fulfilled after the expiration time
    /// @dev The buyer receives the collateral minus a 5% fee
    /// @param agreementId The ID of the agreement to claim the collateral for
    function claimCollateral(uint256 agreementId) public nonReentrant {
        Agreement storage agreement = agreements[agreementId];
        require(msg.sender == agreement.buyer, "Not buyer");
        require(OFFERS_EXPIRED != 0 && OFFERS_EXPIRED < block.timestamp, "Agreement not expired yet");
        require(agreement.active, "Agreement not active");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWL, "Emergency withdrawl enabled");

        uint256 cost = FixedPointMathLib.mulDivUp(agreement.costPerToken, agreement.tokens, OTC_DENOMINATOR);

        uint256 collateral = cost * 25 / 100;
        uint256 fee = collateral * 20 / 100;

        agreement.active = false;

        collateralDeposited[agreement.collateralToken][agreement.seller] -= collateral;
        collateralDeposited[agreement.collateralToken][msg.sender] -= cost;

        IERC20(agreement.collateralToken).transfer(msg.sender, (cost + collateral) - fee);

        IERC20(agreement.collateralToken).transfer(FEE, fee);

        emit Claimed(agreementId, msg.sender, agreement.collateralToken, (cost + collateral) - fee, fee);
    }

    /// @notice Allows users to withdraw their deposited collateral in case of an emergency.
    /// @dev Resets the collateral deposited amount for the user after the withdrawal.
    /// @param _collateralToken The address of the collateral token to withdraw
    function emergencyWithdraw(address _collateralToken) public nonReentrant {
        require(_supportToken.contains(_collateralToken), "Not Supported");
        require(tx.origin == msg.sender, "EOA only");
        require(EMERGENCY_WITHDRAWL, "Emergency not active");
        require(collateralDeposited[_collateralToken][msg.sender] > 0, "No funds available to withdraw");

        uint256 amountDeposited = collateralDeposited[_collateralToken][msg.sender];

        collateralDeposited[_collateralToken][msg.sender] = 0;

        require(IERC20(_collateralToken).transfer(msg.sender, amountDeposited));
    }

    /// @notice Returns an array of trade offers within the specified range
    /// @dev Pagination is used to fetch trade offers in smaller chunks
    /// @param startIndex The start index of the trade offers to fetch
    /// @param endIndex The end index of the trade offers to fetch
    /// @return offers An array of TradeOffer structs within the specified range
    function getOffers(uint256 startIndex, uint256 endIndex) public view returns (TradeOffer[] memory) {
        require(startIndex < endIndex, "Invalid range");

        if (endIndex > tradeOffers.length) endIndex = tradeOffers.length;

        uint256 length = endIndex - startIndex;
        TradeOffer[] memory offers = new TradeOffer[](length);

        for (uint256 i = startIndex; i < endIndex; i++) {
            offers[i - startIndex] = tradeOffers[i];
        }

        return offers;
    }

    /// @notice Returns an array of agreements within the specified range
    /// @dev Pagination is used to fetch agreements in smaller chunks
    /// @param startIndex The start index of the agreements to fetch
    /// @param endIndex The end index of the agreements to fetch
    /// @return agmts An array of Agreement structs within the specified range
    function getAgreements(uint256 startIndex, uint256 endIndex) public view returns (Agreement[] memory) {
        require(startIndex < endIndex, "Invalid range");

        if (endIndex > agreements.length) endIndex = agreements.length;

        uint256 length = endIndex - startIndex;
        Agreement[] memory agmts = new Agreement[](length);

        for (uint256 i = startIndex; i < endIndex; i++) {
            agmts[i - startIndex] = agreements[i];
        }

        return agmts;
    }

    /// @notice Allows the owner set collateral tokens
    /// @dev Only the owner can call this function
    /// @param _collateralTokens The addresses of the tokens to use as collateral
    /// @param _isSupporteds Whether or not the token is supported
    function setSupporteds(address[] memory _collateralTokens, bool[] memory _isSupporteds) external onlyOwner {
        for (uint256 i; i < _collateralTokens.length; i++) {
            if (_isSupporteds[i]) {
                _supportToken.add(_collateralTokens[i]);
            } else {
                if (_supportToken.contains(_collateralTokens[i])) {
                    _supportToken.remove(_collateralTokens[i]);
                }
            }
        }
    }

    /// @notice Returns an array of supported collateral tokens
    function getSupports() external view returns (address[] memory collaterals) {
        uint256 length = _supportToken.length();
        collaterals = new address[](length);
        for (uint256 i; i < length; i++) {
            collaterals[i] = _supportToken.at(i);
        }
    }

    /// @notice Allows the owner to set the OTC address
    /// @dev Only the owner can call this function
    /// @param _OTC The address of the OTC token
    function setOTC(address _OTC) external onlyOwner {
        OTC_ADDRESS = _OTC;
        OTC_DENOMINATOR = 10 ** IERC20Metadata(OTC_ADDRESS).decimals();
    }

    /// @notice Allows the contract owner to set the maximum and minimum acceptable costs per token
    /// @dev This function is restricted to the contract owner
    /// @param _min The minimum acceptable cost per token in USD
    /// @param _max The maximum acceptable cost per token in USD
    function setMaxAndMin(uint256 _min, uint256 _max) public onlyOwner {
        MIN_COST = _min;
        MAX_COST = _max;
    }

    /// @notice Enables/Disables accepting offers
    /// @dev Can only be called by the contract owner.
    /// Disable accepting offers so offers cannot be accepted very close to expiration
    function setAcceptingOffers(bool _state) public onlyOwner {
        ACCEPTING_OFFERS_ENABLED = _state;
    }

    /// @notice Expires all offers
    /// @dev Can only be called by the contract owner.
    /// Owner has incentive to call this at the correct time to maximise fees.
    /// @param endTs The timestamp at which all offers should expire
    function expireOffers(uint256 endTs) public onlyOwner {
        require(endTs > block.timestamp, "Must be in the future");
        OFFERS_EXPIRED = endTs;
        emit Expired(OFFERS_EXPIRED);
    }

    /// @notice Enables emergency withdrawals for users.
    /// @dev Can only be called by the contract owner.
    function triggerEmergencyWithdrawls(bool enabled) public onlyOwner {
        EMERGENCY_WITHDRAWL = enabled;
        emit EmergencyWithdrawlsEnabled(enabled);
    }
}
