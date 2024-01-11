pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IOpenSea.sol";
import "./Types.sol";


contract Matcher is Ownable, Types {

    enum SaleKind { FixedPrice, DutchAuction }
    uint DAI_DEC_CENT = 10**16;

    event MatchProgress(uint indexed stage);
    event NewPF(uint indexed nftId, uint indexed newPrice);


    Seaport public openSea;
    mapping(address => bool) public isValidPayToken;
    address public matchNft;

    uint public gauge = 10000000;
    uint public CONSTANT_GAUGE = 10000000;

    uint public totalSales;
    mapping(uint256 => uint256) public idTotalSales;

    uint256 public priceFloor;
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
                // orders[0].parameters.consideration.length == 3 &&
                orders[1].parameters.offer.length == 1 &&
                // orders[1].parameters.consideration.length == 0 &&
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
        emit MatchProgress(0);
        isMatchable = areMatchable(orders, fulfillments);
        emit MatchProgress(1);
        require(isMatchable);
        uint newPrice = orders[1].parameters.offer[0].endAmount;
        uint256 nftId = orders[0].parameters.offer[0].identifierOrCriteria;
        // price floor write
        idPriceFloor[nftId] = newPrice;
        emit NewPF(nftId, newPrice);
    }

    function matchOrders(Order[] calldata orders, Fulfillment[] calldata fulfillments)
        public
        payable
        returns (Execution[] memory executions)
    {
        require(updPriceWithValidation(orders, fulfillments));
        return openSea.matchOrders(orders, fulfillments);
    }
}
