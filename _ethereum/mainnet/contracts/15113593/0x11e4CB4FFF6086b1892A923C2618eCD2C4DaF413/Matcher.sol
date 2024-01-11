pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IOpenSea.sol";
import "./IToken.sol";
import "./Types.sol";


contract Matcher is Ownable, Types {

    event NewPF(uint indexed nftId, uint indexed newPrice);

    Seaport public openSea;
    mapping(address => bool) public isValidPayToken;
    address public matchNft;

    mapping(uint256 => uint256) public idPriceFloor;

    constructor(address _os, address _pt, address _altPt,  address _nft) {
        openSea = Seaport(_os);
        isValidPayToken[_pt] = true;
        isValidPayToken[_altPt] = true;
        matchNft = _nft;
    }

    function areMatchable(Order[] calldata orders, Fulfillment[] calldata fulfillments) public view returns (bool) {
        OfferItem memory bidOffer = orders[0].parameters.offer[0];
        OfferItem memory listingOffer = orders[1].parameters.offer[0];
        return (orders.length == 2 &&
                fulfillments.length == 4 &&
                orders[0].parameters.orderType == OrderType(2) &&
                orders[1].parameters.orderType == OrderType(2) &&
                orders[0].parameters.offer.length == 1 &&
                orders[1].parameters.offer.length == 1 &&
                listingOffer.itemType == ItemType(2) &&
                listingOffer.token == matchNft &&
                listingOffer.endAmount == 1 && listingOffer.startAmount == 1 &&
                bidOffer.itemType == ItemType(1) &&
                isValidPayToken[bidOffer.token] &&
                bidOffer.endAmount == bidOffer.startAmount &&
                // price floor read
                bidOffer.endAmount > idPriceFloor[listingOffer.identifierOrCriteria]
        );
    }

    function updPriceWithValidation(Order[] calldata orders, Fulfillment[] calldata fulfillments) internal returns (bool isMatchable) {
        isMatchable = areMatchable(orders, fulfillments);
        require(isMatchable);
        uint newPrice = orders[0].parameters.offer[0].endAmount;
        uint256 nftId = orders[1].parameters.offer[0].identifierOrCriteria;
        // price floor write
        idPriceFloor[nftId] = newPrice;
        emit NewPF(nftId, newPrice);
    }

    function matchOrders(Order[] calldata orders, Fulfillment[] calldata fulfillments) public
    {
        require(updPriceWithValidation(orders, fulfillments));
        uint256 nftId = orders[1].parameters.offer[0].identifierOrCriteria;
        IToken(matchNft).setTxOk(nftId, true);
        openSea.matchOrders(orders, fulfillments);
        IToken(matchNft).setTxOk(nftId, false);
    }
}
