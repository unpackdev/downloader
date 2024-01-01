// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "./CLLFactory.sol";
import "./Ownable.sol";

contract CLLMarketplace is Ownable{

    CLLFactory public factory;

    uint256 public locationPriceDivider;

    struct Offer{
      uint256 padlockFirstPriceWei;
      uint256 keyFirstPriceWei;
      uint256 engravingPriceWei;
      bool published;
      bool sold;
      uint8 numberOfKeys;
    }

    mapping(uint256 => Offer) public offers;

    event CLLOfferPublished(
      uint256 indexed padlockTokenId,
      uint256 padlockFirstPriceWei,
      uint256 keyFirstPriceWei,
      uint256 engravingPriceWei,
      uint8 numberOfKeys
    );

    event CLLOfferUnpublished(uint256 indexed padlockTokenId);

    event CLLOfferSold(uint256 indexed padlockTokenId);

    event CLLOfferEngraved(uint256 indexed padlockTokenId);


    constructor(CLLFactory _factory){
      factory = _factory;
      locationPriceDivider = 100;
    }

    function setLocationPriceDivider(uint256 newLocationPriceDivider) external onlyOwner {
      require(newLocationPriceDivider != 0, "Bad price divider");
      locationPriceDivider = newLocationPriceDivider;
    }

    function publishOffer(uint256 padlockTokenId
                        , uint256 padlockFirstPriceWei
                        , uint256 keyFirstPriceWei
                        , uint8   numberOfKeys
                        , uint256 engravingPriceWei) public onlyOwner {

        require(offers[padlockTokenId].sold == false, "Already sold");
        require(offers[padlockTokenId].published == false, "Still published");
        require(padlockFirstPriceWei != 0, "Invalid price");
        require(numberOfKeys <= 16, "Too much keys"); 

        offers[padlockTokenId] = Offer({
          padlockFirstPriceWei: padlockFirstPriceWei,
          keyFirstPriceWei: keyFirstPriceWei,
          numberOfKeys: numberOfKeys,
          engravingPriceWei: engravingPriceWei,
          published: true,
          sold: false
        });

        emit CLLOfferPublished(
          padlockTokenId,
          offers[padlockTokenId].padlockFirstPriceWei,
          offers[padlockTokenId].keyFirstPriceWei,
          offers[padlockTokenId].engravingPriceWei,
          offers[padlockTokenId].numberOfKeys
        );
    }


    function unpublishOffer(uint256 padlockTokenId) public onlyOwner {
        require(offers[padlockTokenId].padlockFirstPriceWei
                != 0, "Non existent offer");
        require(offers[padlockTokenId].sold == false, "Already sold");
        require(offers[padlockTokenId].published == true, "Not published");

        offers[padlockTokenId].published = false;

        emit CLLOfferUnpublished(padlockTokenId);

    }

    function buyPadlockAndKeys(uint256 padlockTokenId) public payable{

        require(offers[padlockTokenId].padlockFirstPriceWei
                != 0, "Non existent offer");
        require(offers[padlockTokenId].sold == false, "Already sold");
        require(offers[padlockTokenId].published == true, "Not published");

        Offer memory offer = offers[padlockTokenId];

        uint256 requiredWei = offer.padlockFirstPriceWei +
                              offer.numberOfKeys * offer.keyFirstPriceWei;
        require(msg.value >= requiredWei, "Not enough money");

        factory.mintPadlockAndKeysTo(msg.sender, padlockTokenId, offer.numberOfKeys);

        offers[padlockTokenId].published = false;
        offers[padlockTokenId].sold= true;

        emit CLLOfferSold(padlockTokenId);
    }

    function buyPadlockAndKeysAndEngrave(uint256 padlockTokenId
                    ,bytes32 text_1
                    ,bytes32 text_2
                    ,bytes32 text_3) public payable {

        require(offers[padlockTokenId].padlockFirstPriceWei
                != 0, "Non existent offer");
        require(offers[padlockTokenId].sold == false, "Already sold");
        require(offers[padlockTokenId].published == true, "Not published");

        Offer memory offer = offers[padlockTokenId];

        uint256 requiredWei = offer.padlockFirstPriceWei +
                              offer.numberOfKeys * offer.keyFirstPriceWei +
                              offer.engravingPriceWei/2;

        require(msg.value >= requiredWei, "Not enough money");

        factory.mintPadlockAndKeysTo(msg.sender, padlockTokenId, offer.numberOfKeys);

        offers[padlockTokenId].published = false;
        offers[padlockTokenId].sold= true;

        factory.engravePadlock(msg.sender, padlockTokenId, text_1, text_2, text_3);

        emit CLLOfferSold(padlockTokenId);
    }

    function engraveLater( uint256 padlockTokenId
                          ,bytes32 text_1
                          ,bytes32 text_2
                          ,bytes32 text_3) external payable{

      require(offers[padlockTokenId].padlockFirstPriceWei
              != 0, "Non existent offer");
      require(offers[padlockTokenId].sold == true, "Must be sold");
      require(offers[padlockTokenId].published == false, "Must not be published");

      Offer memory offer = offers[padlockTokenId];
      uint256 requiredWei = offer.engravingPriceWei;
      require(msg.value >= requiredWei, "Not enough money");

      factory.engravePadlock(msg.sender, padlockTokenId, text_1, text_2, text_3);

    }

    function setPadlockLocation( uint256 padlock
                                ,uint256 key
                                ,uint256 location
                                ,bytes32 location_extra_data) external payable{

      uint256 requiredWei = offers[padlock].padlockFirstPriceWei / locationPriceDivider;
      require(msg.value >= requiredWei, "Not enough money");

      factory.setPadlockLocation(msg.sender, padlock, key, location, location_extra_data);
    }

    function withdrawFunds(uint256 value, address payable recipient) onlyOwner external{
        recipient.transfer(value);
    }

    function balance() view onlyOwner external returns(uint256) {
        return address(this).balance;
    }
}

