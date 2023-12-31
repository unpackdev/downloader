// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC777.sol";
import "./ReentrancyGuard.sol";
import "./IERC777Recipient.sol";
import "./IERC1820Registry.sol";
import "./Initializable.sol";
import "./Strings.sol";
import "./EnumerableSet.sol";


import "./RestrictedBlackHolePrevention.sol";
import "./IRegistryConsumer.sol";

import "./console.sol";

/*

replace tokenIds arrays with sets

getter needs pagination

*/

contract Marketplace is ReentrancyGuard, IERC777Recipient, RestrictedBlackHolePrevention, ERC165 {
    using EnumerableSet for EnumerableSet.UintSet;

    function version() public view virtual returns (uint256) {
        return 20230807;
    }

    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);


    uint32   public communityId;
    IERC721 public _tokenContract; // ERC721 NFT token contract instance

    struct Offer {
        bool    isForSale; // flag to check sale status
        address seller;
        uint256 value;
        address sellOnlyTo; // specify to sell only to a specific address
        address erc777Address;
    }

    // map offers and bids for each token
    mapping(uint256 => Offer) public cardsForSaleInETH; // map of card id to offer struct of cards for sale in ETH
    mapping(uint256 => Offer) public cardsForSaleInERC777; // map of card id to offer struct of cards for sale in ERC777

    EnumerableSet.UintSet private _allCardsForSaleInETH; // dynamic array of all token ids on sale in ETH
    EnumerableSet.UintSet private _allCardsForSaleInERC777; // dynamic array of all token ids on sale in ERC777

    event OfferForSale(address _from, address _to, uint256 _tokenId, uint256 _value, bool _useERC777,address erc777Address);
    event OfferExecuted(address _from, address _to, uint256 _tokenId, uint256 _value, bool _useERC777, address erc777Address);
    event OfferRevoked(address _from, address _to, uint256 _tokenId, uint256 _value, bool _useERC777,address erc777Address);
    event OfferModified(address _from, uint256 _tokenId, uint256 _value, address _sellOnlyTo, bool _useERC777,address erc777Address);

    bool initialised;


    modifier onlyCardOwner(uint256 _tokenId) {
        require(_tokenContract.ownerOf(_tokenId) == msg.sender, "Marketplace: Not NFT owner");
        _;
    }

    /**
    @param _tokenAddress address of the IERC721 NFT contract
    which is to be traded on this marketplace instance
    @param _owner address of the owner of thei smarketplace instance.
    Ownership will be transferred to this address after the deployment
    succeeds.
     */
    function init(
        address _tokenAddress,
        uint32 _communityId,
        address _owner
    ) external  {
        require(!initialised,"Contract already initialised");
        initialised = true;
        require(_tokenAddress != address(0), "Marketplace: Null address not accepted");
        require(_owner != address(0), "Marketplace: Null address not accepted");

        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));

        _tokenContract = IERC721(_tokenAddress);
        communityId = _communityId;
        _transferOwnership(_owner);
    }

    /**
    @inheritdoc IERC777Recipient
     */
    function tokensReceived(
        address operator,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external view override {
        // handle incoming ERC777 when bids are made
        //this won't work because bid can be in DUST or GLX
        //require(msg.sender == address(_getAcceptedERC777()), "Marketplace: Invalid token type");
        require(operator == address(this),"Marketplace: invalid operator"); // stop trapped tokens
    }

    //________________________________Offers______________________________

    function _offerCardForSale(
        uint256 _tokenId,
        uint256 _minPrice,
        address _sellOnlyTo,
        bool _useERC777,
        address _ERC777address
    ) private onlyCardOwner(_tokenId) {
        // check if the contract is approved by token owner
        require(_tokenContract.isApprovedForAll(msg.sender, address(this)), "Marketplace: Contract not authorized");

        // if using ERC777, check that it is the current one
        checkCurrent777(_useERC777,_ERC777address);
        // check if price is set to higher than 0
        require(_minPrice > 0, "Marketplace: Offer price must be > 0");
        require(_sellOnlyTo != msg.sender, "Marketplace: Sell only to address cannot be seller's address");

        // initialize offer
        if (_useERC777) {
            
            // create id => offer mapping
            cardsForSaleInERC777[_tokenId] = Offer(
                true,
                msg.sender,
                _minPrice,
                _sellOnlyTo,
                _ERC777address
            );
            // save card id to list of cards on sale
             
            _allCardsForSaleInERC777.add(_tokenId);
        } else {
            
            // create id => offer mapping
            cardsForSaleInETH[_tokenId] = Offer(
                true,
                msg.sender,
                _minPrice,
                _sellOnlyTo,
                address(0)
            );
            // save card id to list of cards on sale
            _allCardsForSaleInETH.add(_tokenId);
        }
        // emit sale event
        emit OfferForSale(msg.sender, _sellOnlyTo, _tokenId, _minPrice, _useERC777,_ERC777address);
    }

    function offerCardForSaleInETH(
        uint256 _tokenId,
        uint256 _minPrice,
        address _sellOnlyTo
    ) external {
        _offerCardForSale(_tokenId, _minPrice, _sellOnlyTo, false,address(0));
    }

    function offerCardForSaleInERC777(
        uint256 _tokenId,
        uint256 _minPrice,
        address _sellOnlyTo,
        address _erc777Address
    ) external {
        _offerCardForSale(_tokenId, _minPrice, _sellOnlyTo, true,_erc777Address);
    }

    function _modifyOffer(
        uint256 _tokenId,
        uint256 _value,
        address _sellOnlyTo,
        bool _useERC777,
        address _erc777Address
    ) private onlyCardOwner(_tokenId) {
        Offer memory offer = _useERC777 ? cardsForSaleInERC777[_tokenId] : cardsForSaleInETH[_tokenId];

        require(offer.isForSale, "Marketplace: This token is not for sale");
        require(offer.erc777Address == _erc777Address, "Marketplace: sale token different");
        require(_value > 0, "Marketplace: Offer price must be > 0");
        require(_sellOnlyTo != msg.sender, "Marketplace: Sell only to address cannot be seller's address");

        Offer memory newOffer = Offer(
            offer.isForSale,
            offer.seller,
            _value,
            _sellOnlyTo,
            offer.erc777Address
        );
        // modify offer
        if (_useERC777) {
            cardsForSaleInERC777[_tokenId] = newOffer;
        } else {
            cardsForSaleInETH[_tokenId] = newOffer;
        }
        emit OfferModified(msg.sender, _tokenId, _value, _sellOnlyTo, _useERC777,_erc777Address);
    }

    function modifyEtherOffer(
        uint256 _tokenId,
        uint256 _value,
        address _sellOnlyTo
    ) external {
        _modifyOffer(_tokenId, _value, _sellOnlyTo, false,address(0));
    }

    function modifyERC777Offer(
        uint256 _tokenId,
        uint256 _value,
        address _sellOnlyTo,
        address _erc777Address
    ) external {
        _modifyOffer(_tokenId, _value, _sellOnlyTo, true,_erc777Address);
    }

    function _revokeOffer(uint256 _tokenId, bool _useERC777) private onlyCardOwner(_tokenId) {
        Offer memory offer = _useERC777 ? cardsForSaleInERC777[_tokenId] : cardsForSaleInETH[_tokenId];
        require(offer.isForSale, "Marketplace: This token is not for sale");
        _deleteOffer(_tokenId, _useERC777);
        Offer memory newOffer = Offer(false, address(0), 0, address(0), address(0));
        if (_useERC777) {
            cardsForSaleInERC777[_tokenId] = newOffer;
        } else {
            cardsForSaleInETH[_tokenId] = newOffer;
        }
        emit OfferRevoked(offer.seller, offer.sellOnlyTo, _tokenId, offer.value, _useERC777,offer.erc777Address);
    }

    function revokeEtherOffer(uint256 _tokenId) external {
        _revokeOffer(_tokenId, false);
    }

    function revokeERC777Offer(uint256 _tokenId) external {
        _revokeOffer(_tokenId, true);
    }

    function _buyItNow(uint256 _tokenId, bool _useERC777, uint256  _priceToPay, address _777Address) private nonReentrant {
        Offer memory offer = _useERC777 ? cardsForSaleInERC777[_tokenId] : cardsForSaleInETH[_tokenId];
        // check if the offer is valid
        require(offer.isForSale, "Marketplace: This token is not for sale");
        require(offer.seller != address(0), "Marketplace: This token is not for sale");
        require(offer.value > 0, "Marketplace: This token is not for sale");
        require(offer.erc777Address == _777Address,"Marketplace: payment in wrong token");

        // check if it is for sale for someone specific
        if (offer.sellOnlyTo != address(0)) {
            // only sell to someone specific
            require(offer.sellOnlyTo == msg.sender, "Marketplace: This token is not for sale for buyer");
        }

        // make sure buyer is not the owner
        require(msg.sender != _tokenContract.ownerOf(_tokenId), "Marketplace: buyer is token owner!");

        // check approval status, user may have modified transfer approval
        require(_tokenContract.isApprovedForAll(offer.seller, address(this)), "Marketplace: Contract not authorized");

        if (_useERC777) {
            // check if buyer has enough ERC777 to purchase
            require(
                IERC777(offer.erc777Address).balanceOf(msg.sender) >= offer.value &&
                _priceToPay >= offer.value, "Marketplace: Not enough ERC777");
        } else {
            // check if offer value and sent values match
            require(offer.value == msg.value, "Marketplace: Not enough ETH sent");
        }

        // make sure the seller is the owner
        require(offer.seller == _tokenContract.ownerOf(_tokenId), "Marketplace: seller no longer owns NFT");

        // save the seller variable
        address seller = offer.seller;

        // delete offers for this card
        _deleteOffer(_tokenId, true);
        _deleteOffer(_tokenId, false);


        // first send the token to the buyer
        _tokenContract.safeTransferFrom(seller, msg.sender, _tokenId); // non reentrant is essential here

        // transfer ether to acceptor and pay royalty to the community owner
        if (_useERC777) {
            _transferERC777(msg.sender, seller, offer.value,offer.erc777Address); // non reentrant is essential here
        } else {
            _sendETH(seller, offer.value);
        }

        // check if the user recieved the item
        require(_tokenContract.ownerOf(_tokenId) == msg.sender);

        // emit event
        emit OfferExecuted(offer.seller, msg.sender, _tokenId, offer.value, _useERC777,offer.erc777Address);
    }

    function buyItNowForEther(uint256 _tokenId) external payable {
        _buyItNow(_tokenId, false, msg.value,address(0));
    }

    function buyItNowForERC777(uint256 _tokenId, uint256 _priceToPay, address _777address) external {
        _buyItNow(_tokenId, true, _priceToPay,_777address);
    }

 
    function numberOfERC777Offers() external view returns (uint256) {
        return _allCardsForSaleInERC777.length();
    }

    function numberOfEtherOffers() external  view returns (uint256) {
        return _allCardsForSaleInETH.length();
    }

    function getAllERC777Offers(uint start, uint len) external view returns (uint256[] memory) {
        return enumerate(_allCardsForSaleInERC777,start,len);
    }

    function getAllEtherOffers(uint start, uint len) external view returns (uint256[] memory) {
        return enumerate(_allCardsForSaleInETH,start,len);
    }

    function enumerate(EnumerableSet.UintSet storage data, uint start, uint len) internal view returns (uint256[] memory result) {
        if (start >= data.length()) {
            return result;
        }
        if (start + len > data.length()) {
            len = data.length() - start;
        }
        result = new uint256[](len);
        for (uint i = 0; i < len; i++) {
            result[i] = data.at(start+i);
        }
    }

    function _transferERC777(
        address _buyer,
        address _seller,
        uint256 _amount,
        address _erc777
    ) private {
        // send to seller
        IERC777(_erc777).operatorSend(_buyer, _seller, _amount , "", ""); // if seller rejects it nothing lost
    }


    function _getAcceptedERC777() internal view returns (IERC777) {
        return IERC777(_galaxisRegistry.getRegistryAddress("MARKETPLACE_ACCEPTED_ERC777"));
    }

    

    function _deleteOffer(uint256 _tokenId, bool _useERC777) private {
        if ( _useERC777) {
            _allCardsForSaleInERC777.remove(_tokenId);
            delete cardsForSaleInERC777[_tokenId];
        } else {
            _allCardsForSaleInETH.remove(_tokenId);
            delete cardsForSaleInETH[_tokenId];
        }
    }


    function _sendERC777(address _receiver, uint256 _amount, address _token777) internal {
        bytes memory data;
        bool         sent;
        bytes memory datafield  = abi.encodeWithSelector(
            IERC777.send.selector,
            _receiver,
            _amount,
            data
        );
        (sent, ) = _token777.call(datafield);
        require(sent,"Marketplace: seller cannot receive payment");
    }



    function _sendETH(address _receiver, uint256 _amount) internal {
        (bool sent, ) = _receiver.call{value: _amount}("");
        require(sent,"Marketplace: seller cannot receive payment");
    }

    function checkCurrent777(bool _useERC777, address _ERC777address) internal view {
        if (_useERC777) {
            require(
                _ERC777address == _galaxisRegistry.getRegistryAddress("MARKETPLACE_ACCEPTED_ERC777"),
                "Marketplace: Payment token is not the current GALAXIS payment token"
            );
        } else {
            require (
                _ERC777address == address(0),
                "Marketplace: address should be zero if not using ERC777"
            );
        }
    }

    /**
    @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
        return 
            interfaceId == type(IERC777Recipient).interfaceId ||
            super.supportsInterface(interfaceId);
    }


}
