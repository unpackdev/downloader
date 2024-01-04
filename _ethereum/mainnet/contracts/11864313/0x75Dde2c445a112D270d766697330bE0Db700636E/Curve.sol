// SPDX-License-Identifier: MIT
// Based on https://github.com/simondlr/neolastics/blob/master/packages/hardhat/contracts/Curve.sol

pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";


abstract contract Curve is IERC721, IERC721Enumerable {
    using SafeMath for uint256;

    uint256 public initMintPrice = 0.005 ether;    // at 0
    uint256 public initBurnPrice = 0.00475 ether;   // at 1

    // You technically do not need to keep tabs on the reserve
    // because it uses linear pricing
    // but useful to know off-hand. Especially because this.balance might not be the same as the actual reserve
    uint256 public reserve;

    uint nextTokenId;

    address payable public creator;

    event Minted(uint256 indexed tokenId, uint256 indexed pieceId, uint256 pricePaid, uint256 indexed reserveAfterMint);
    event Burned(uint256 indexed tokenId, uint256 indexed pieceId, uint256 priceReceived, uint256 indexed reserveAfterBurn);

    /*
    todo: 
    flash minting protection
    front-running exploits
    */
    constructor (address payable _creator) {
        creator = _creator;
        reserve = 0;
        nextTokenId = 1;
    }

    /*
    The original neolastics contract has a note about front-running here. As far as I can tell, this concern comes
    from the fact that the front-end includes a buffer when sending payment, which might allow a bot to jump in front,
    get the non-buffered price, then burn their own token for the now increased curve price once the front-runned
    tx makes it onto the chain. We do not intend to include a frontend buffer for now, but if we did, I believe the
    same logic applies: Our small price increases + creator fee + gas price should make it unprofitable.
    */
    function mint() public virtual payable returns (uint256 _tokenId) {
        // you can only mint one at a time.
        require(msg.value > 0, "C: No ETH sent");

        uint256 mintPrice = getCurrentPriceToMint();
        require(msg.value >= mintPrice, "C: Not enough ETH sent");

        // mint first to increase supply.
        uint256 tokenId = nextTokenId;
        nextTokenId++;
        uint256 pieceId = onMint(tokenId);

        // disburse
        uint256 reserveCut = getReserveCut();
        reserve = reserve.add(reserveCut);
        creator.transfer(mintPrice.sub(reserveCut));

        if (msg.value.sub(mintPrice) > 0) {
            msg.sender.transfer(msg.value.sub(mintPrice)); // excess/padding/buffer
        }

        emit Minted(tokenId, pieceId, mintPrice, reserve);

        return tokenId; // returns tokenId in case its useful to check it
    }

    function burn(uint256 tokenId) public virtual {
        require(msg.sender == this.ownerOf(tokenId), "not-owner");

        uint256 burnPrice = getCurrentPriceToBurn();
        uint256 pieceId = onBurn(tokenId);

        reserve = reserve.sub(burnPrice);
        msg.sender.transfer(burnPrice);

        emit Burned(tokenId, pieceId, burnPrice, reserve);
    }

    // if supply 0, mint price = 0.001
    function getCurrentPriceToMint() public virtual view returns (uint256) {
        uint256 mintPrice = initMintPrice.add(this.totalSupply().mul(initMintPrice));
        return mintPrice;
    }

    // helper function for legibility
    function getReserveCut() public virtual view returns (uint256) {
        return getCurrentPriceToBurn();
    }

    // if supply 1, then burn price = 0.000995
    function getCurrentPriceToBurn() public virtual view returns (uint256) {
        uint256 burnPrice = this.totalSupply().mul(initBurnPrice);
        return burnPrice;
    }

    function onMint(uint256 tokenId) internal virtual returns (uint256 pieceId);
    function onBurn(uint256 tokenId) internal virtual returns (uint256 pieceId);
}