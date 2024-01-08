//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IRoyaltyEngineV1.sol";

contract NFTFloorMarket is ReentrancyGuard, Ownable {

    // Events
    event OfferPlaced(
        uint256 _offerId,
        address indexed _contract,
        address _offerer,
        uint256 _value
    );

    event OfferWithdrawn(
        uint256 _offerId,
        address indexed _contract,
        address _offerer,
        uint256 _value
    );

    event OfferAccepted(
        uint256 _offerId,
        address indexed _contract,
        address _offerer,
        address _seller,
        uint256 _tokenId,
        uint256 _value
    );


    // Offer Structure
    struct Offer {
        address _contract;
        address _offerer;
        uint256 _value;
        uint128 _contractListIndex; // This and the following are 128 to make use of bitpacking on the struct
        uint128 _offererListIndex;
    }

    // Offer Details Structure
    struct OfferDetails {
        uint256 _offerId;
        address _contract;
        address _offerer;
        uint256 _value;
    }


    // Keep track of latest offer ID
    uint256 public lastOfferId = 0;

    // Keep track of all offers
    mapping(uint256 => Offer) public offers;

    // Keep track of offer IDs per contract
    mapping(address => uint128[]) public offersByContract;

    // Keep track of offer per offerer address
    mapping(address => uint128[]) public offersByOfferer;



    // Market Fees
    uint8   public MARKET_FEE_DIVIDEND = 200; // Comes out to 0.5%
    address public MARKET_FEE_ADDRESS;


    // Royalty Fee Address
    address public MANIFOLD_ROYALTY_ENGINE;


    // Anti-Griefing
    uint256 public MINIMUM_BUY_OFFER = 10000000000000000; // 0.01 ETH


    /**
     * Market Fee Address - all market fees get sent here
     **/
    function setMarketFeeAddress(address _addr) public onlyOwner {
        MARKET_FEE_ADDRESS = _addr;
    }

    /**
     * Royalties - lookup for all royalty addresses
     **/
    function setRoyaltyEngineAddress(address _addr) public onlyOwner {
        MANIFOLD_ROYALTY_ENGINE = _addr;
    }

    /**
     * Set the minimum buy order amount - anti-griefing mechanic
     **/
    function setMinimumBuyOffer(uint256 _minValue) public onlyOwner {
        MINIMUM_BUY_OFFER = _minValue;
    }


    /**
     * Constructor
     **/
    constructor(
        address _MARKET_FEE_ADDRESS,
        address _MANIFOLD_ROYALTY_ENGINE,
        uint256 _MINIMUM_BUY_OFFER
    ) {
        setMarketFeeAddress(_MARKET_FEE_ADDRESS);
        setRoyaltyEngineAddress(_MANIFOLD_ROYALTY_ENGINE);
        setMinimumBuyOffer(_MINIMUM_BUY_OFFER);
    }


    /**
     * Wrapper to get all royalties for a given contract + tokenId at a given value
     **/
    function getRoyalties(
        address _contract,
        uint256 _tokenId,
        uint256 _value
    )
        public
        view
        returns (
            address payable[] memory recipients,
            uint256[] memory amounts
        )
    {
        if (MANIFOLD_ROYALTY_ENGINE != address(0)) {
            try IRoyaltyEngineV1(MANIFOLD_ROYALTY_ENGINE).getRoyaltyView(_contract, _tokenId, _value) returns(address payable[] memory _recipients, uint256[] memory _amounts) {
                return (_recipients, _amounts);
            } catch {}
        }
    }


    /**
     * Make an offer on any NFT within a contract
     **/
    function makeOffer(
        address _contract
    )
        public
        payable
        nonReentrant
    {
        // Require that the contract is a valid ERC721 token
        require(IERC721(_contract).supportsInterface(0x80ac58cd), "Not a valid ERC-721 Contract");
        require(msg.value >= MINIMUM_BUY_OFFER, "Buy order too low");

        // Store the records
        offers[lastOfferId] = Offer(
            _contract,
            msg.sender,
            msg.value,
            uint128(offersByContract[_contract].length),
            uint128(offersByOfferer[msg.sender].length)
        );
        offersByContract[_contract].push(uint128(lastOfferId));
        offersByOfferer[msg.sender].push(uint128(lastOfferId));

        // On to the next offer ID
        lastOfferId += 1;

        // Announce offer placed
        emit OfferPlaced(lastOfferId, _contract, msg.sender, msg.value);
    }


    /**
     * Withdraw an offer on any NFT within a contract
     **/
    function withdrawOffer(
        uint256 _offerId
    )
        public
        nonReentrant
    {
        // Get the offer
        Offer memory _offer = offers[_offerId];

        // Make sure that the sender is the owner of the offer ID
        require(_offer._offerer == msg.sender, "Sender does not own offer");

        // Remove the offer
        _removeOffer(_offer, _offerId);

        // Send the value back to the offerer
        msg.sender.call{value: _offer._value}('');

        // Announce offer withdrawn
        emit OfferWithdrawn(_offerId, _offer._contract, msg.sender, _offer._value);
    }


    /**
     * Take an offer on any NFT within a contract
     **/
    function takeOffer(
        uint256 _offerId,
        uint256 _tokenId
    )
        public
        nonReentrant
    {
        // Get the offer
        Offer memory _offer = offers[_offerId];

        // Make sure the offer exists
        require(_offer._contract != address(0), "Offer does not exist");

        // Remove the offer
        _removeOffer(_offer, _offerId);

        // Transfer NFT to the buyer
        IERC721(_offer._contract).safeTransferFrom(msg.sender, _offer._offerer, _tokenId, "");

        // Retrieve the royalties here
        uint256 totalRoyaltyFee;
        (address payable[] memory _recipients, uint256[] memory _amounts) = getRoyalties(_offer._contract, _tokenId, _offer._value);
        if (_recipients.length > 0 && _amounts.length > 0 && _amounts.length == _recipients.length) {
            for (uint256 idx; idx < _recipients.length; idx++) {
                totalRoyaltyFee += _amounts[idx];
                _recipients[idx].call{value: _amounts[idx]}('');
            }
        }

        // Get the market fee
        uint256 marketFee = _offer._value / MARKET_FEE_DIVIDEND;

        // Split the value among royalties, seller, and market
        uint256 sellerValue;
        if (_offer._value < (marketFee + totalRoyaltyFee)) {
            // In the exceptionally strange case where value < market fee + royalty fee, leave out the market fee since royalty fees
            //  need to be less than or equal to provided value (per external contract logic)
            sellerValue = _offer._value - totalRoyaltyFee;
        } else {
            sellerValue = _offer._value - marketFee - totalRoyaltyFee;
        }

        // Send the value to the seller
        msg.sender.call{value: sellerValue}('');

        // Send the market fee to the market fee address
        MARKET_FEE_ADDRESS.call{value: marketFee}('');

        // Announce offer accepted
        emit OfferAccepted(_offerId, _offer._contract, _offer._offerer, msg.sender, _tokenId, _offer._value);
    }


    /**
     * Getters
     **/
    function getOffersByContractCount(
        address _contract
    )
        public
        view
        returns (uint256 _length)
    {
        return offersByContract[_contract].length;
    }

    function getOffersByContract(
        address _contract,
        uint256 _limit,
        uint256 _offset
    )
        public
        view
        returns (OfferDetails[] memory _offers)
    {
        // Limits & Offers
        if (_limit == 0) {
            _limit = 1;
        }

        // Keep track of all offers
        _offers = new OfferDetails[](_limit);

        // Iterate through offers by contract
        uint256 offerIdx;
        for (uint256 idx = _offset * _limit; idx < offersByContract[_contract].length && offerIdx < _limit; idx++) {
            _offers[offerIdx++] = OfferDetails(
                offersByContract[_contract][idx],
                offers[offersByContract[_contract][idx]]._contract,
                offers[offersByContract[_contract][idx]]._offerer,
                offers[offersByContract[_contract][idx]]._value
            );
        }

        return _offers;
    }

    function getOffersByOffererCount(
        address _offerer
    )
        public
        view
        returns (uint256 _length)
    {
        return offersByOfferer[_offerer].length;
    }

    function getOffersByOfferer(
        address _offerer,
        uint256 _limit,
        uint256 _offset
    )
        public
        view
        returns (OfferDetails[] memory _offers)
    {
        // Limits & Offers
        if (_limit == 0) {
            _limit = 1;
        }

        // Keep track of all offers
        _offers = new OfferDetails[](_limit);

        // Iterate through offers by contract
        uint256 offerIdx;
        for (uint256 idx = _offset * _limit; idx < offersByOfferer[_offerer].length && offerIdx < _limit; idx++) {
            _offers[offerIdx++] = OfferDetails(
                offersByOfferer[_offerer][idx],
                offers[offersByOfferer[_offerer][idx]]._contract,
                offers[offersByOfferer[_offerer][idx]]._offerer,
                offers[offersByOfferer[_offerer][idx]]._value
            );
        }

        return _offers;
    }


    /**
     * Internal Helper Functions 
     **/
    function _removeOffer(Offer memory _offer, uint256 _offerId) private {
        // Find and remove from the contract list and offerer list
        _removeFromContractList(_offer._contract, _offer._contractListIndex);
        _removeFromOffererList(_offer._offerer, _offer._offererListIndex);

        // Remove the offer
        delete offers[_offerId];
    }


    function _removeFromContractList(address _contract, uint128 index) private {
        uint256 _length = offersByContract[_contract].length;

        // If this index is less than the last element, then replace this element with the last element
        if (index < _length - 1) {
            // Get the last offer ID in the list
            uint128 otherOfferId = offersByContract[_contract][_length - 1];

            // Replace with the last element
            offersByContract[_contract][index] = otherOfferId;

            // Update the position within offers
            offers[otherOfferId]._contractListIndex = index;
        }

        // Remove the last index
        offersByContract[_contract].pop();
    }

    function _removeFromOffererList(address offerer, uint128 index) private {
        uint256 _length = offersByOfferer[offerer].length;

        // If this index is less than the last element, then replace this element with the last element
        if (index < _length - 1) {
            // Get the last offer ID in the list
            uint128 otherOfferId = offersByOfferer[offerer][_length - 1];

            // Replace with the last element
            offersByOfferer[offerer][index] = otherOfferId;

            // Update the position within offers
            offers[otherOfferId]._offererListIndex = index;
        }

        // Remove the last index
        offersByOfferer[offerer].pop();
    }


    /**
     * Do not accept value sent directly to contract
     **/
    receive() external payable {
        revert("No value accepted");
    }
}
