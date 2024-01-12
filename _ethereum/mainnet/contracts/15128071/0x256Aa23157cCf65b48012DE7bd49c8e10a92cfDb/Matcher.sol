pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IOpenSea.sol";
import "./IToken.sol";
import "./Types.sol";


contract Matcher is Ownable, Types {

    event NewPF(uint indexed nftId, uint indexed newPrice);

    Seaport public openSea;
    address public osConduit;
    address public matchNft;
    address public weth;
    // step - require next trade to be above idPriceFloor by this amount
    uint256 public step;
    uint constant MAX_UINT = 2**256 - 1;


    mapping(uint256 => uint256) public idPriceFloor;

    constructor(address _os, address _conduit, address _weth, address _nft) {
        openSea = Seaport(_os);
        matchNft = _nft;
        weth = _weth;
        osConduit = _conduit;
        IToken(weth).approve(osConduit, MAX_UINT);
    }

    function setStep(uint256 _step) public onlyOwner {
        require(_step < 2);
        step = _step * 10**18;
    }

    function getFinalPrice(ConsiderationItem[] calldata considerations) internal pure returns (uint256) {
        require(considerations.length == 2, "cons");
        require(considerations[0].token == address(0), "ct");
        require(considerations[1].token == address(0), "ct2");
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
                bidOffer.token == weth &&
                bidOffer.endAmount == bidOffer.startAmount &&
                // price floor read
                base18price > idPriceFloor[listingOffer.identifierOrCriteria] + step &&
                bidOffer.endAmount >= base18price
        );
    }

    function updPriceWithValidation(Order[] calldata orders, Fulfillment[] calldata fulfillments) internal returns (uint256) {
        uint256 base18price = getFinalPrice(orders[1].parameters.consideration);
        require(areMatchable(orders, fulfillments, base18price), "match");
        uint256 nftId = orders[1].parameters.offer[0].identifierOrCriteria;
        // price floor write
        idPriceFloor[nftId] = base18price;
        emit NewPF(nftId, base18price);
        return base18price;
    }

    function matchOrders(Order[] calldata orders, Fulfillment[] calldata fulfillments) public
    {
        uint256 base18price = updPriceWithValidation(orders, fulfillments);
        uint256 nftId = orders[1].parameters.offer[0].identifierOrCriteria;
        //nft seller - listing
        address xorFrom = IToken(matchNft).ownerOf(nftId);
        IToken(matchNft).openMatch(nftId, xorFrom, osConduit);
        openSea.fulfillOrder(orders[0], orders[0].parameters.conduitKey);
        IToken(weth).withdraw(IToken(weth).balanceOf(address(this)));
        //nft buyer - order
        address xorTo = IToken(matchNft).ownerOf(nftId);
        IToken(matchNft).restoreMatch(nftId, xorTo, xorFrom);
        openSea.fulfillOrder{value: base18price}(orders[1], orders[1].parameters.conduitKey);
        IToken(matchNft).closeMatch(nftId, xorTo);
    }

    function claimETHfees() public onlyOwner {
        address payable _to = payable(msg.sender);
        _to.transfer(address(this).balance);
    }

    function unwrapWETHfees() public onlyOwner {
        IToken(weth).withdraw(IToken(weth).balanceOf(address(this)));
    }
}
