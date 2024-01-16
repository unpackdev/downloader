// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./IERC777Recipient.sol";
import "./IERC1820Registry.sol";

import "./Splitter.sol";

contract Marketplace is Ownable, ReentrancyGuard, IERC777Recipient {
    string public name; // conctract name
    uint16 public totalSupply; // number of NFTs in circulation
    uint16 public royalty; // royalty percentage (expressed in tenthousandths 0-10000, this gives two decimal resolution)

    address public tokenContractAddress; // ERC721 NFT contract address
    IERC721 private tokenContract; // ERC721 NFT token contract

    address public dustContractAddress; // ERC777 NFT token address (DUST)
    IERC777 private dustContract; // DUST ERC777 NFT token contract (DUST)

    address payable public splitterContractAddress; // Splitter contract for splitting royalty address
    Splitter private splitterContract; // Splitter contract for splitting royalty

    IERC1820Registry private _erc1820 =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    struct Offer {
        bool isForSale; // cariable to check sale status
        address seller; // seller address
        uint256 value; // in ether
        address onlySellTo; // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid; // variable to check bid status
        address bidder; // bidder address
        uint256 value; // in ether or DUST
    }

    // map offers and bids for each token
    mapping(uint256 => Offer) public cardsForSaleInETH; // list of cards of for sale in ETH
    mapping(uint256 => Offer) public cardsForSaleInDust; // list of cards of for sale in DUST
    mapping(uint256 => Bid) public etherBids; // list of ether bids on cards
    mapping(uint256 => Bid) public dustBids; // list of DUST bids on cards
    mapping(address => bool) public permitted; // permitted to modify owner royalty
    mapping(address => uint256) private bidsDustReceived; // mapping from bidder address to DUST received from address

    event OfferForSale(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _value,
        bool _isDust
    );
    event OfferExecuted(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _value,
        bool _isDust
    );
    event OfferRevoked(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _value,
        bool _isDust
    );

    event OfferModified(
        address _from,
        uint16 _tokenId,
        uint256 _value,
        address _sellOnlyTo,
        bool _isDust
    );

    event BidReceived(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _newValue,
        uint256 _prevValue,
        bool _isDust
    );

    event BidAccepted(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _value,
        bool _isDust
    );

    event BidRevoked(
        address _from,
        uint16 _tokenId,
        uint256 _value,
        bool _isDust
    );

    event RoyaltyChanged(address _from, uint16 _royalty);

    modifier onlyCardOwner(uint16 _tokenId) {
        // need to check before calling ownerOf()
        require(_tokenId < totalSupply, "Invalid token ID!");
        require(
            tokenContract.ownerOf(_tokenId) == msg.sender,
            "Sender does not own this token."
        );
        _;
    }

    constructor(
        string memory _name,
        address _tokenContractAddress,
        address _dustContractAddress,
        address payable _splitterContractAddress,
        uint16 _totalSupply,
        uint16 _royalty
    ) {
        name = _name; // set the name for display purposes
        setTotalSupply(_totalSupply); // set total supply for token
        setRoyalty(_royalty); // set royalty

        // initialize the 721 NFT contract
        require(
            _tokenContractAddress != address(0),
            "Splitter contract address cannot be ZERO address."
        );
        tokenContractAddress = _tokenContractAddress;
        tokenContract = IERC721(_tokenContractAddress);

        // initialize the Splitter contract
        require(
            _splitterContractAddress != address(0),
            "Splitter contract address cannot be ZERO address."
        );
        splitterContractAddress = _splitterContractAddress;
        splitterContract = Splitter(_splitterContractAddress);

        // initalize DUST contract
        require(
            _dustContractAddress != address(0),
            "Dust contract address cannot be ZERO address."
        );
        dustContractAddress = _dustContractAddress;
        dustContract = IERC777(_dustContractAddress);

        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        ); // register self with IERC1820 registry
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        // handle incoming DUST when bids are made
        require(msg.sender == dustContractAddress, "Invalid token!");
        bidsDustReceived[from] += amount;
    }

    function _split(address _seller, uint256 _amount) internal {
        uint256 royaltyAmount = (_amount * royalty) / 10000;

        bool success;
        (success, ) = splitterContractAddress.call{value: royaltyAmount}("");
        require(success, "Transfer failed!");

        uint256 sellerAmount = _amount - royaltyAmount;
        (success, ) = _seller.call{value: sellerAmount}("");
        require(success, "Transfer failed!");
    }

    function _splitDust(
        address _buyer,
        address _seller,
        uint256 _amount
    ) internal {
        // in case of Dust transaction, send Dust to Splitter's ERC777 account
        uint256 royaltyAmount = (_amount * royalty) / 10000;
        dustContract.operatorSend(
            _buyer,
            splitterContractAddress,
            royaltyAmount,
            "",
            ""
        );

        uint256 sellerAmount = _amount - royaltyAmount;
        dustContract.operatorSend(_buyer, _seller, sellerAmount, "", "");
    }

    function offerCardForSaleSellOnlyTo(
        uint16 _tokenId,
        uint256 _minPrice,
        address _sellOnlyTo
    ) external onlyCardOwner(_tokenId) {
        // check if the contract is approved by token owner
        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)),
            "Contract is not approved."
        );

        // check if card id is correct
        require(
            _tokenId < totalSupply,
            "Token ID should be smaller than total supply."
        );
        // check if price is set to higher than 0
        require(_minPrice > 0, "Price should be higher than 0.");
        require(
            _sellOnlyTo != address(0),
            "Sell only to address cannot be null."
        );
        require(
            _sellOnlyTo != msg.sender,
            "Sell only to address cannot be self."
        );
        // initialize offer for only 1 buyer - _sellOnlyTo
        cardsForSaleInETH[_tokenId] = Offer(
            true,
            msg.sender,
            _minPrice,
            _sellOnlyTo
        );

        // emit sale event
        emit OfferForSale(msg.sender, _sellOnlyTo, _tokenId, _minPrice, false);
    }

    function offerCardForSale(uint16 _tokenId, uint256 _minPriceInWei)
        external
        onlyCardOwner(_tokenId)
    {
        // check if the contract is approved by token owner
        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)),
            "Contract is not approved."
        );

        // check if card id is correct
        require(
            _tokenId < totalSupply,
            "Token ID should be smaller than total supply."
        );
        // check if price is set to higher than 0
        require(_minPriceInWei > 0, "Price should be higher than 0.");

        // initialize offer for only 1 buyer - _sellOnlyTo
        cardsForSaleInETH[_tokenId] = Offer(
            true,
            msg.sender,
            _minPriceInWei,
            address(0)
        );

        // emit sale event
        emit OfferForSale(
            msg.sender,
            address(0),
            _tokenId,
            _minPriceInWei,
            false
        );
    }

    function offerCardForSaleInDust(uint16 _tokenId, uint256 _minPrice)
        external
        onlyCardOwner(_tokenId)
    {
        // check if the contract is approved by token owner
        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)),
            "Contract is not approved."
        );

        // check if card id is correct
        require(
            _tokenId < totalSupply,
            "Token ID should be smaller than total supply."
        );
        // check if price is set to higher than 0
        require(_minPrice > 0, "Price should be higher than 0.");

        // initialize offer for only 1 buyer - _sellOnlyTo
        cardsForSaleInDust[_tokenId] = Offer(
            true,
            msg.sender,
            _minPrice,
            address(0)
        );

        // emit sale event
        emit OfferForSale(msg.sender, address(0), _tokenId, _minPrice, true);
    }

    function offerCardForSaleInDustSellOnlyTo(
        uint16 _tokenId,
        uint256 _minPrice,
        address _sellOnlyTo
    ) external onlyCardOwner(_tokenId) {
        // check if the contract is approved by token owner
        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)),
            "Contract is not approved."
        );

        // check if card id is correct
        require(
            _tokenId < totalSupply,
            "Token ID should be smaller than total supply."
        );
        // check if price is set to higher than 0
        require(_minPrice > 0, "Price should be higher than 0.");
        // make sure sell only to is not 0x0
        require(
            _sellOnlyTo != address(0),
            "Sell only to address cannot be null."
        );

        // make sure sell only to address is not self
        require(
            _sellOnlyTo != msg.sender,
            "Sell only to address cannot be self."
        );

        // initialize offer for only 1 buyer - _sellOnlyTo
        cardsForSaleInDust[_tokenId] = Offer(
            true,
            msg.sender,
            _minPrice,
            _sellOnlyTo
        );

        // emit sale event
        emit OfferForSale(msg.sender, _sellOnlyTo, _tokenId, _minPrice, true);
    }

    function modifyEtherOffer(
        uint16 _tokenId,
        uint256 _value,
        address _sellOnlyTo
    ) external onlyCardOwner(_tokenId) {
        Offer memory offer = cardsForSaleInETH[_tokenId];

        require(offer.isForSale, "No offer exists for this token!");
        require(_value > 0, "Price should be higher than 0.");
        require(
            _sellOnlyTo != msg.sender,
            "Sell only to address cannot be self!"
        );

        // modify offer
        cardsForSaleInETH[_tokenId] = Offer(
            offer.isForSale,
            offer.seller,
            _value,
            _sellOnlyTo
        );
        emit OfferModified(msg.sender, _tokenId, _value, _sellOnlyTo, false);
    }

    function modifyDustOffer(
        uint16 _tokenId,
        uint256 _value,
        address _sellOnlyTo
    ) external onlyCardOwner(_tokenId) {
        Offer memory offer = cardsForSaleInDust[_tokenId];

        require(offer.isForSale, "No offer exists for this token!");
        require(_value > 0, "Price should be higher than 0.");
        require(
            _sellOnlyTo != msg.sender,
            "Sell only to address cannot be self!"
        );

        // modify offer
        require(_value > 0, "Price should be higher than 0.");
        cardsForSaleInDust[_tokenId] = Offer(
            offer.isForSale,
            offer.seller,
            _value,
            _sellOnlyTo
        );
        emit OfferModified(msg.sender, _tokenId, _value, _sellOnlyTo, true);
    }

    function revokeEtherOffer(uint16 _tokenId)
        external
        onlyCardOwner(_tokenId)
    {
        Offer memory offer = cardsForSaleInETH[_tokenId];
        require(offer.isForSale, "No offer exists for this token.");

        cardsForSaleInETH[_tokenId] = Offer(false, address(0), 0, address(0));
        emit OfferRevoked(
            offer.seller,
            offer.onlySellTo,
            _tokenId,
            offer.value,
            false
        );
    }

    function revokeDustOffer(uint16 _tokenId) external onlyCardOwner(_tokenId) {
        Offer memory offer = cardsForSaleInDust[_tokenId];
        require(offer.isForSale, "No offer exists for this token.");

        cardsForSaleInDust[_tokenId] = Offer(false, address(0), 0, address(0));
        emit OfferRevoked(
            offer.seller,
            offer.onlySellTo,
            _tokenId,
            offer.value,
            true
        );
    }

    function buyItNowForEther(uint16 _tokenId) external payable nonReentrant {
        Offer memory offer = cardsForSaleInETH[_tokenId];
        // check if the offer is valid
        require(offer.isForSale, "This token is not for sale.");
        require(offer.seller != address(0), "This token is not for sale.");
        require(offer.value > 0, "This token is not for sale.");

        // check if it is for sale for someone specific
        if (offer.onlySellTo != address(0)) {
            // only sell to someone specific
            require(
                offer.onlySellTo == msg.sender,
                "This coin can be sold only for a specific address."
            );
        }

        // make sure buyer is not the owner
        require(
            msg.sender != tokenContract.ownerOf(_tokenId),
            "Buyer already owns this token."
        );

        // check approval status, user may have modified transfer approval
        require(
            tokenContract.isApprovedForAll(offer.seller, address(this)),
            "Contract is not approved."
        );

        // check if offer value and sent values match
        require(
            offer.value == msg.value,
            "Offer ask price and sent ETH mismatch!"
        );

        // make sure the seller is the owner
        require(
            offer.seller == tokenContract.ownerOf(_tokenId),
            "Seller no longer owns this token."
        );

        // save the seller variable
        address seller = offer.seller;

        // reset offers for this card
        cardsForSaleInETH[_tokenId] = Offer(false, address(0), 0, address(0));
        cardsForSaleInDust[_tokenId] = Offer(false, address(0), 0, address(0));

        // check if there were any ether bids on this card
        Bid memory bid = etherBids[_tokenId];
        if (bid.hasBid) {
            // save bid values and bidder variables
            address bidder = bid.bidder;
            uint256 amount = bid.value;
            // reset bid
            etherBids[_tokenId] = Bid(false, address(0), 0);
            // send back bid value to bidder
            bool sent;
            (sent, ) = bidder.call{value: amount}("");
            require(sent, "Failed to send back ether to bidder.");
        }

        // check if there were any DUST bids on this card
        Bid memory dustBid = dustBids[_tokenId];
        if (dustBid.hasBid) {
            // save bid values and bidder variables
            address bidder = dustBid.bidder;
            uint256 amount = dustBid.value;
            // reset bid
            etherBids[_tokenId] = Bid(false, address(0), 0);
            // send back bid value to bidder
            dustContract.operatorSend(address(this), bidder, amount, "", "");
        }

        // first send the token to the buyer
        tokenContract.safeTransferFrom(seller, msg.sender, _tokenId);

        // transfer ether to acceptor and pay royalty to the community owner
        _split(seller, offer.value);

        // check if the user recieved the item
        require(tokenContract.ownerOf(_tokenId) == msg.sender);

        // emit event
        emit OfferExecuted(
            offer.seller,
            msg.sender,
            _tokenId,
            offer.value,
            false
        );
    }

    function buyItNowForDust(uint16 _tokenId) external nonReentrant {
        Offer memory offer = cardsForSaleInDust[_tokenId];
        // check if the offer is valid
        require(offer.isForSale, "This token is not for sale.");
        require(offer.seller != address(0), "This token is not for sale.");
        require(offer.value > 0, "This token is not for sale.");

        // check if it is for sale for someone specific
        if (offer.onlySellTo != address(0)) {
            // only sell to someone specific
            require(
                offer.onlySellTo == msg.sender,
                "This coin can be sold only for a specific address."
            );
        }

        // make sure buyer is not the owner
        require(
            msg.sender != tokenContract.ownerOf(_tokenId),
            "Buyer already owns this token."
        );

        // check approval status, user may have modified transfer approval
        require(
            tokenContract.isApprovedForAll(offer.seller, address(this)),
            "Contract is not approved."
        );

        // check if buyer has enough Dust to purchase
        require(
            dustContract.balanceOf(msg.sender) >= offer.value,
            "Not enough DUST!"
        );

        // make sure the seller is the owner
        require(
            offer.seller == tokenContract.ownerOf(_tokenId),
            "Seller no longer owns this token."
        );

        // save the seller variable
        address seller = offer.seller;

        // reset offers for this card
        cardsForSaleInETH[_tokenId] = Offer(false, address(0), 0, address(0));
        cardsForSaleInDust[_tokenId] = Offer(false, address(0), 0, address(0));

        // check if there were any ether bids on this card
        Bid memory bid = etherBids[_tokenId];
        if (bid.hasBid) {
            // save bid values and bidder variables
            address bidder = bid.bidder;
            uint256 amount = bid.value;
            // reset bid
            etherBids[_tokenId] = Bid(false, address(0), 0);
            // send back bid value to bidder
            bool sent;
            (sent, ) = bidder.call{value: amount}("");
            require(sent, "Failed to send back ether to bidder.");
        }

        // check if there were any DUST bids on this card
        Bid memory dustBid = dustBids[_tokenId];
        if (dustBid.hasBid) {
            // save bid values and bidder variables
            address bidder = dustBid.bidder;
            uint256 amount = dustBid.value;
            // reset bid
            etherBids[_tokenId] = Bid(false, address(0), 0);
            // send back bid value to bidder
            dustContract.operatorSend(address(this), bidder, amount, "", "");
        }

        // first send the token to the buyer
        tokenContract.safeTransferFrom(seller, msg.sender, _tokenId);

        // transfer dust to acceptor and pay royalty to the community owner
        _splitDust(msg.sender, seller, offer.value);

        // check if the user recieved the item
        require(tokenContract.ownerOf(_tokenId) == msg.sender);

        // emit event
        emit OfferExecuted(
            offer.seller,
            msg.sender,
            _tokenId,
            offer.value,
            true
        );
    }

    function bidOnCardWithEther(uint16 _tokenId) external payable nonReentrant {
        // check if card id is valid
        require(
            _tokenId < totalSupply,
            "Token ID should be smaller than total supply."
        );
        address cardOwner = tokenContract.ownerOf(_tokenId);
        // make sure the bidder is not the owner
        require(msg.sender != cardOwner, "Cannot bid on owned card.");
        // check if bid value is valid
        require(msg.value > 0, "Bid price has to be higher than 0.");

        Bid memory bid = etherBids[_tokenId];
        // initialize the bid with the new values
        etherBids[_tokenId] = Bid(true, msg.sender, msg.value);

        // emit event
        emit BidReceived(
            msg.sender,
            cardOwner,
            _tokenId,
            msg.value,
            bid.value,
            false
        );

        // check if there were any bids on this card
        if (bid.hasBid) {
            // the current bid has to be higher than the previous
            require(bid.value < msg.value, "Bid price is below current bid.");
            address previousBidder = bid.bidder;
            uint256 amount = bid.value;
            // pay back the previous bidder's ether
            bool sent;
            (sent, ) = previousBidder.call{value: amount}("");
            require(sent, "Failed to send back ether to previous bidder.");
        }
    }

    function bidOnCardWithDust(uint16 _tokenId, uint256 _bidValue)
        external
        nonReentrant
    {
        require(
            _tokenId < totalSupply,
            "Token ID should be smaller than total supply."
        );
        address cardOwner = tokenContract.ownerOf(_tokenId);
        // make sure the bidder is not the owner
        require(msg.sender != cardOwner, "Cannot bid on owned card.");
        // check if bid value is valid
        require(_bidValue > 0, "Bid price has to be higher than 0.");
        // check if bid value is valid
        require(
            dustContract.balanceOf(msg.sender) >= _bidValue,
            "Not enough DUST!"
        );
        Bid memory bid = dustBids[_tokenId];
        // initialize the bid with the new values
        dustBids[_tokenId] = Bid(true, msg.sender, _bidValue);

        // emit event
        emit BidReceived(
            msg.sender,
            cardOwner,
            _tokenId,
            _bidValue,
            bid.value,
            true
        );

        // check if there were any bids on this card
        if (bid.hasBid) {
            // the current bid has to be higher than the previous
            require(bid.value < _bidValue, "Bid price is below current bid.");
            address previousBidder = bid.bidder;
            uint256 amount = bid.value;
            // pay back the previous bidder's ether
            dustContract.operatorSend(
                address(this),
                previousBidder,
                amount,
                "",
                ""
            );
        }

        // move DUST into marketplace contract
        dustContract.operatorSend(msg.sender, address(this), _bidValue, "", "");
    }

    function acceptEtherBid(uint16 _tokenId) external onlyCardOwner(_tokenId) {
        Bid memory bid = etherBids[_tokenId];

        // make sure there is a valid bid on the card
        require(bid.hasBid, "This token has no bid on it.");
        // check if the contract is still approved for transfer
        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)),
            "Contract is not approved."
        );

        // reset offers for this token
        cardsForSaleInETH[_tokenId] = Offer(false, address(0), 0, address(0));
        cardsForSaleInDust[_tokenId] = Offer(false, address(0), 0, address(0));

        address buyer = bid.bidder;
        uint256 amount = bid.value;

        Bid memory dustBid = dustBids[_tokenId];

        // reset bids
        etherBids[_tokenId] = Bid(false, address(0), 0);
        dustBids[_tokenId] = Bid(false, address(0), 0);

        // refund dust for bidder if any
        if (dustBid.hasBid) {
            dustContract.send(dustBid.bidder, dustBid.value, "");
        }

        // transfer ether to acceptor and pay royalty to the community owner
        _split(msg.sender, amount);
        // send token from acceptor to the bidder
        tokenContract.safeTransferFrom(msg.sender, buyer, _tokenId);

        // check if the user received the token
        require(tokenContract.ownerOf(_tokenId) == buyer);

        // emit event
        emit BidAccepted(msg.sender, bid.bidder, _tokenId, amount, false);
    }

    function acceptDustBid(uint16 _tokenId)
        external
        onlyCardOwner(_tokenId)
        nonReentrant
    {
        Bid memory bid = dustBids[_tokenId];

        // make sure there is a valid bid on the card
        require(bid.hasBid, "This token has no bid on it.");
        // check if the contract is still approved for transfer
        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)),
            "Contract is not approved."
        );

        // reset offers for this token
        cardsForSaleInETH[_tokenId] = Offer(false, address(0), 0, address(0));
        cardsForSaleInDust[_tokenId] = Offer(false, address(0), 0, address(0));

        address buyer = bid.bidder;
        uint256 amount = bid.value;

        Bid memory etherBid = etherBids[_tokenId];
        // reset bids
        etherBids[_tokenId] = Bid(false, address(0), 0);
        dustBids[_tokenId] = Bid(false, address(0), 0);

        // refund current ether bid if any
        if (etherBid.hasBid) {
            (bool success, ) = etherBid.bidder.call{value: etherBid.value}("");
            require(success, "Transfer failed!");
        }

        // transfer ether to acceptor and pay royalty to the community owner
        _splitDust(address(this), msg.sender, amount);

        // send token from acceptor to the bidder
        tokenContract.safeTransferFrom(msg.sender, buyer, _tokenId);

        // check if the user received the token
        require(tokenContract.ownerOf(_tokenId) == buyer);

        // emit event
        emit BidAccepted(msg.sender, bid.bidder, _tokenId, amount, true);
    }

    function revokeEtherBid(uint16 _tokenId) external {
        Bid memory bid = etherBids[_tokenId];
        // check if the bid exists
        require(bid.hasBid, "This token has no bid on it.");
        // check if the bidder is the sender of the message
        require(
            bid.bidder == msg.sender,
            "Sender is not the current highest bidder."
        );
        // save bid value into a variable
        uint256 amount = bid.value;

        // reset bid
        etherBids[_tokenId] = Bid(false, address(0), 0);

        // emit event
        emit BidRevoked(msg.sender, _tokenId, amount, false);

        // transfer back their ether
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to retrieve ether.");
    }

    function revokeDustBid(uint16 _tokenId) external {
        Bid memory bid = dustBids[_tokenId];
        // check if the bid exists
        require(bid.hasBid, "This token has no bid on it.");
        // check if the bidder is the sender of the message
        require(
            bid.bidder == msg.sender,
            "Sender is not the current highest bidder."
        );
        // save bid value into a variable
        uint256 amount = bid.value;

        // reset bid
        dustBids[_tokenId] = Bid(false, address(0), 0);

        // emit event
        emit BidRevoked(msg.sender, _tokenId, amount, true);

        // refund DUST
        dustContract.send(msg.sender, amount, "");
    }

    // getters

    function getEtherOfferValueForCard(uint16 _tokenId)
        external
        view
        returns (uint256)
    {
        return cardsForSaleInETH[_tokenId].value;
    }

    function getDustOfferValueForCard(uint16 _tokenId)
        external
        view
        returns (uint256)
    {
        return cardsForSaleInDust[_tokenId].value;
    }

    function getSellOnlyToAddressForOffer(uint16 _tokenId, bool _dust)
        internal
        view
        returns (address)
    {
        require(_tokenId < totalSupply, "Invalid token ID!");
        Offer memory offer = cardsForSaleInETH[_tokenId];
        if (_dust) {
            offer = cardsForSaleInDust[_tokenId];
        }
        require(offer.isForSale, "This token is not for sale!");
        return offer.onlySellTo;
    }

    function getSellOnlyToAddressForDustOffer(uint16 _tokenId)
        external
        view
        returns (address)
    {
        return getSellOnlyToAddressForOffer(_tokenId, true);
    }

    function getSellOnlyToAddressForEtherOffer(uint16 _tokenId)
        external
        view
        returns (address)
    {
        return getSellOnlyToAddressForOffer(_tokenId, false);
    }

    function getHighestBidForCard(uint16 _tokenId, bool _dust)
        internal
        view
        returns (uint256)
    {
        require(_tokenId < totalSupply, "Invalid token ID!");
        Bid memory bid = etherBids[_tokenId];
        if (_dust) {
            bid = dustBids[_tokenId];
        }
        require(bid.hasBid, "This token has no bid on it!");
        return bid.value;
    }

    function getHighestEtherBidForCard(uint16 _tokenId)
        external
        view
        returns (uint256)
    {
        return getHighestBidForCard(_tokenId, false);
    }

    function getHighestDustBidForCard(uint16 _tokenId)
        external
        view
        returns (uint256)
    {
        return getHighestBidForCard(_tokenId, true);
    }

    function getHighestBidder(uint16 _tokenId, bool _dust)
        internal
        view
        returns (address)
    {
        require(_tokenId < totalSupply, "Invalid token ID!");
        Bid memory bid = etherBids[_tokenId];
        if (_dust) {
            bid = dustBids[_tokenId];
        }
        require(bid.hasBid, "This token has no bid on it!");
        return bid.bidder;
    }

    function getHighestEtherBidderForCard(uint16 _tokenId)
        external
        view
        returns (address)
    {
        return getHighestBidder(_tokenId, false);
    }

    function getHighestDustBidderForCard(uint16 _tokenId)
        external
        view
        returns (address)
    {
        return getHighestBidder(_tokenId, true);
    }

    function setRoyalty(uint16 _royalty) public onlyOwner {
        require(royalty <= 10000, "Royalty value should be below 10000.");
        royalty = _royalty;
        emit RoyaltyChanged(msg.sender, _royalty);
    }
    
    function setTotalSupply(uint16 _totalSupply) public onlyOwner {
        totalSupply = _totalSupply;
    }

}
