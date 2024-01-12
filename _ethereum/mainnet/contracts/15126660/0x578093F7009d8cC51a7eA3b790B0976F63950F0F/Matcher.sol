pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IOpenSea.sol";
import "./IToken.sol";
import "./Types.sol";


contract Matcher is Ownable, Types {

    event NewPF(uint indexed nftId, uint indexed newPrice);
    uint constant MAX_UINT = 2**256 - 1;

    Seaport public openSea;
    address public osConduit = 0x1E0049783F008A0085193E00003D00cd54003c71;
    mapping(address => bool) public isValidPayToken;
    address public matchNft;
    address public USDC;
    // step - require next trade to be above idPriceFloor by this amount
    uint256 public step;


    mapping(uint256 => uint256) public idPriceFloor;

    constructor(address _os, address _pt, address _altPt,  address _nft) {
        openSea = Seaport(_os);
        isValidPayToken[_pt] = true;
        isValidPayToken[_altPt] = true;
        matchNft = _nft;
        USDC = _altPt;
    }

    function setStep(uint256 _step) public onlyOwner {
        require(_step < 1000);
        step = _step * 10**18;
    }

    function getFinalPrice(ConsiderationItem[] calldata considerations) internal pure returns (uint256) {
        require(considerations.length == 2, "cons");
        return considerations[0].endAmount + considerations[1].endAmount;
    }

    function areMatchable(Order[] calldata orders, Fulfillment[] calldata fulfillments, uint256 base18price) public view returns (bool) {
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
                base18price > idPriceFloor[listingOffer.identifierOrCriteria]
        );
    }

    function updPriceWithValidation(Order[] calldata orders, Fulfillment[] calldata fulfillments) internal returns (bool isMatchable) {
        uint256 finalPrice = getFinalPrice(orders[1].parameters.consideration);
        uint256 base18price;
        if (orders[0].parameters.offer[0].token == USDC) {
           base18price = finalPrice * 10**12;
        } else {
           base18price = finalPrice;
        }
        isMatchable = areMatchable(orders, fulfillments, base18price);
        require(isMatchable);
        uint256 nftId = orders[1].parameters.offer[0].identifierOrCriteria;
        // price floor write
        idPriceFloor[nftId] = base18price + step;
        emit NewPF(nftId, base18price);
    }

    function matchOrders(Order[] calldata orders, Fulfillment[] calldata fulfillments) public
    {
        require(updPriceWithValidation(orders, fulfillments));
        emit Progress(1);
        IToken(orders[0].parameters.offer[0].token).approve(osConduit, MAX_UINT);
        uint256 nftId = orders[1].parameters.offer[0].identifierOrCriteria;
        bytes32 conduitKey = orders[0].parameters.conduitKey;
        address xorFrom = IToken(matchNft).ownerOf(nftId);
        emit Progress(2);
        IToken(matchNft).openMatch(nftId, xorFrom, osConduit);
        emit Progress(3);
        openSea.fulfillOrder(orders[0], conduitKey);
        emit Progress(4);
        address xorTo = IToken(matchNft).ownerOf(nftId);
        emit Progress(5);
        IToken(matchNft).restoreMatch(nftId, xorFrom);
        emit Progress(6);
        openSea.fulfillOrder(orders[1], conduitKey);
        emit Progress(7);
        IToken(matchNft).closeMatch(nftId, xorTo);
    }

//TODO
//dai approvals
//switch to eth/weth only
//


// ------DEV ZONE-------- remove on deploy
//

    event Progress(uint indexed _match);

// sample conduitKey
// 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000

}
