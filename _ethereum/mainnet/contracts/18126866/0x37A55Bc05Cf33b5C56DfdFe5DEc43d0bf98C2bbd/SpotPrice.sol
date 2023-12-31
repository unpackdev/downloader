// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeCast.sol";
import "./AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract SpotPrice is ERC721, Ownable {
    struct Offer {
        uint40 timestamp;
        address to;
    }

    struct Collection {
        uint8 totalSupply;
        uint8 minted;
        uint256[] pricesUsd;
    }

    string internal __baseURI;
    address payable internal _receiver;
    AggregatorV3Interface internal _aggregator;
    bool internal _canTransferGuard;

    uint16[] internal _collectionIds;
    mapping(uint16 => Collection) internal _collections;
    mapping(uint256 => Offer) internal _offers;

    constructor(
        string memory baseURI,
        address payable receiver,
        AggregatorV3Interface aggregator
    ) ERC721("Spot Price", "SP") {
        __baseURI = baseURI;
        _receiver = receiver;
        _aggregator = aggregator;

        Collection storage collection2000 = _collections[2000];
        collection2000.pricesUsd = [
            6805.96 ether,
            7267.54 ether,
            7800.94 ether,
            8187.34 ether,
            8457.68 ether
        ];
        collection2000.totalSupply = 5;
        _collectionIds.push(2000);

        Collection storage collection2006 = _collections[2006];
        collection2006.pricesUsd = [
            6885.48 ether,
            7462.00 ether,
            7852.32 ether,
            8318.24 ether,
            8821.68 ether
        ];
        collection2006.totalSupply = 5;
        _collectionIds.push(2006);

        Collection storage collection2010 = _collections[2010];
        collection2010.pricesUsd = [
            5562 ether,
            5127 ether,
            5214 ether,
            5592 ether,
            6063 ether
        ];
        collection2010.totalSupply = 5;
        _collectionIds.push(2010);
    }

    function mint(address to, uint256 tokenId) public payable {
        uint16 collectionId = SafeCast.toUint16(tokenId / 100);
        uint8 index = uint8(tokenId % 100);

        Collection storage collection = _collections[collectionId];

        require(
            index > 0 && index <= collection.totalSupply,
            "SP: invalid tokenId"
        );

        collection.minted++;
        _mint(to, tokenId);

        // Owner mints for free
        if (msg.sender == owner()) {
            require(msg.value == 0, "SP: wrong amount");
        } else {
            _checkPriceAndTransfer(collection, _receiver);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        __baseURI = baseURI;
    }

    function addPrices(
        uint16[] calldata collectionIds,
        uint256[] calldata pricesUsd
    ) public onlyOwner {
        require(
            collectionIds.length == pricesUsd.length,
            "SP: lentgh mismatch"
        );

        for (uint256 i = 0; i < collectionIds.length; i++) {
            uint16 collectionId = collectionIds[i];
            uint256 priceUsd = pricesUsd[i];
            Collection storage collection = _collections[collectionId];
            require(
                collection.totalSupply > 0,
                "SP: collection does not exist"
            );
            collection.pricesUsd.push(priceUsd);
        }
    }

    function setReceiver(address payable receiver) public onlyOwner {
        _receiver = receiver;
    }

    function removePrices(uint16[] calldata collectionIds) public onlyOwner {
        for (uint256 i = 0; i < collectionIds.length; i++) {
            uint16 collectionId = collectionIds[i];
            Collection storage collection = _collections[collectionId];
            require(
                collection.totalSupply > 0,
                "SP: collection does not exist"
            );
            collection.pricesUsd.pop();
        }
    }

    function getState()
        public
        view
        returns (
            uint16[] memory,
            Collection[] memory,
            address[] memory,
            Offer[] memory,
            uint[] memory,
            string memory
        )
    {
        Collection[] memory collections = new Collection[](
            _collectionIds.length
        );
        uint256 tokensIndex;

        for (uint256 i = 0; i < _collectionIds.length; i++) {
            uint16 collectionId = _collectionIds[i];
            Collection memory collection = _collections[collectionId];
            collections[i] = collection;
            tokensIndex += collection.totalSupply;
        }

        address[] memory owners = new address[](tokensIndex);
        Offer[] memory offers = new Offer[](tokensIndex);
        uint[] memory prices = new uint[](tokensIndex);

        tokensIndex = 0;

        for (uint256 i = 0; i < _collectionIds.length; i++) {
            uint16 collectionId = _collectionIds[i];
            Collection memory collection = _collections[collectionId];
            for (uint256 j = 0; j < collection.totalSupply; j++) {
                uint256 tokenId = uint(collectionId) * 100 + j + 1;
                owners[tokensIndex] = _ownerOf(tokenId);
                offers[tokensIndex] = _offers[tokenId];
                prices[tokensIndex] = convertUsdToEth(
                    collection.pricesUsd[collection.pricesUsd.length - 1]
                );
                tokensIndex++;
            }
        }

        return (_collectionIds, collections, owners, offers, prices, __baseURI);
    }

    function sell(uint256 tokenId, address to) public {
        require(
            msg.sender == ownerOf(tokenId),
            "SP: only token owner can sell"
        );
        _offers[tokenId] = Offer(uint40(block.timestamp), to);
    }

    function buy(uint256 tokenId) public payable {
        uint16 collectionId = SafeCast.toUint16(tokenId / 100);
        Collection storage collection = _collections[collectionId];
        Offer memory offer = _offers[tokenId];

        require(collection.totalSupply > 0, "SP: collection does not exist");
        require(
            collection.pricesUsd[collection.pricesUsd.length - 1] > 0,
            "SP: token is free"
        );
        require(offer.timestamp != 0, "SP: offer doesn't exist");
        require(
            msg.sender == offer.to || offer.to == address(0),
            "SP: cannot match offer"
        );

        _checkPriceAndTransfer(collection, payable(ownerOf(tokenId)));
        delete _offers[tokenId];
        _canTransferGuard = true;
        _transfer(ownerOf(tokenId), msg.sender, tokenId);
    }

    function revoke(uint256 tokenId) public {
        require(
            msg.sender == ownerOf(tokenId),
            "SP: only owner can revoke offers"
        );
        delete _offers[tokenId];
    }

    function _checkPriceAndTransfer(
        Collection memory collection,
        address payable to
    ) internal {
        uint256 priceEth = convertUsdToEth(
            collection.pricesUsd[collection.pricesUsd.length - 1]
        );
        require(msg.value >= priceEth, "SP: wrong amount");
        // Why `call`: https://solidity-by-example.org/sending-ether/
        (bool success, ) = to.call{ value: address(this).balance }("");
        require(success, "SP: unable to transfer ether");
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256 tokenId,
        uint256
    ) internal override {
        uint16 collectionId = SafeCast.toUint16(tokenId / 100);
        uint256[] memory pricesUsd = _collections[collectionId].pricesUsd;
        uint256 price = pricesUsd[pricesUsd.length - 1];
        require(
            _canTransferGuard || from == address(0) || price == 0,
            "SP: cannot transfer"
        );
        _canTransferGuard = false;
    }

    function convertUsdToEth(uint256 value) public view returns (uint256) {
        return
            uint256(
                PriceConverter.convertFrom(
                    _aggregator,
                    SafeCast.toInt256(value)
                )
            );
    }

    function convertEthToUsd(uint256 value) public view returns (uint256) {
        return
            uint256(
                PriceConverter.convertTo(_aggregator, SafeCast.toInt256(value))
            );
    }
}
