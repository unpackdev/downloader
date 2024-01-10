pragma solidity ^0.8.9;

import "./CountersUpgradeable.sol";
import "./FixedPriceMarketPlace.sol";
import "./AuctionMarketPlace.sol";
contract NFTationStorage {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter internal _tokenIdCounter;
    FixedPriceMarketPlace internal fixedPriceMarketPlaceContract;
    AuctionMarketPlace internal auctionMarketPlaceContract;
    mapping(uint256 => bool) internal tokenFirstSaleMapping;
    mapping(uint256 => Royalty) internal royalties;

    struct Royalty {
        address receiver;
        uint256 percentage;
    }
    
    uint256[44] private __gap;
}