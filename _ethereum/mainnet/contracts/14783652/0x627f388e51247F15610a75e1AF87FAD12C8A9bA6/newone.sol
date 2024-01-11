// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Ownable.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract OVT is ERC721URIStorage, Ownable, ContextMixin, NativeMetaTransaction {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIds;
    string private _baseTokenURI;
    address proxyRegistryAddress;

    // Mapping of cardIds to how many exist
    mapping(uint256 => uint256) private _supplyOfCards;

    struct Card {
        // maximum purchase allowed
        uint256 maxPurchase;
        // the maxiumum supply allowed
        uint256 maxSupply;
        // the price of the card
        uint256 price;
    }

    event CardsAdded(
        uint256 cardId,
        uint256 maxPurchase,
        uint256 maxSupply,
        uint256 price
    );

    Card[] private cards;

    constructor(string memory baseTokenURI, address _proxyRegistryAddress)
        ERC721("Ovation", "OVT")
    {
        _baseTokenURI = baseTokenURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        // initialise tokenId to 1, since starting at 0 leads to higher gas cost for the first minter
        _tokenIds.increment();
        _initializeEIP712("Ovation");
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function changebaseURI(string memory newBaseURI)
        public
        onlyOwner
        returns (string memory)
    {
        _baseTokenURI = newBaseURI;

        return _baseTokenURI;
    }

    // Add a cardId instance
    function addCards(
        uint256 maxPurchase,
        uint256 maxSupply,
        uint256 price
    ) public onlyOwner {
        // push new cards to array
        cards.push(Card(maxPurchase, maxSupply, price));
        // get the new length of cards array/new cards id
        uint256 cardId = cards.length - 1;
        // emit an event with all this info
        emit CardsAdded(cardId, maxPurchase, maxSupply, price);
    }

    // internal func to add cards when minted to the supply tracking
    function addToSupply(uint256 cardId, uint256 amount) internal {
        uint256 newAmount = _supplyOfCards[cardId].add(amount);
        _supplyOfCards[cardId] = newAmount;
    }

    function supplyOfCard(uint256 cardId) public view returns (uint256) {
        return _supplyOfCards[cardId];
    }

    // Main mint function
    function mintOVT(
        address account,
        uint256 cardId,
        uint256 amount
    ) public payable {
        // check how this behaves
        // appears to check 3 things at once
        // 1.)supply isn't maxed already
        // 2.)that the purchase won't exceed the max supply
        // 3.)if the card even exists (conseqeuntially)
        require(
            supplyOfCard(cardId).add(amount) <= cards[cardId].maxSupply,
            "Purchase would exceed max supply of card"
        );

        // check that user may purchase as many cards as they are attempting
        require(
            amount <= cards[cardId].maxPurchase,
            "You may not mint this many of this card at once"
        );

        // check the value sent is correct
        require(
            cards[cardId].price.mul(amount) <= msg.value,
            "Ether value sent is not correct"
        );

        addToSupply(cardId, amount);

        string memory _tokenURI = Strings.toString(cardId);

        for (uint256 i = 0; i < amount; i++) {
            // get the new item's id
            uint256 newItemId = _tokenIds.current();
            // set counter ready for next time
            _tokenIds.increment();

            _mint(account, newItemId);
            _setTokenURI(newItemId, _tokenURI);
        }
    }

    // total tokens minted
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current() - 1;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
