// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract Nippleverse is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    bool public SALE_OPEN = false;

    uint256 private constant PRICE = 69 * 10**15; // 0.069ETH Per Nipple
    uint256 private constant PRICE_PRESALE = 5 * 10**16; // 0.05ETH Per Nipple
    uint256 private constant PRICE_PREMINT = 0; // Free Per Nipple

    uint256 private constant MAX_ELEMENTS = 4444; // 4444 Nipples for Entire Collection.
    uint256 private constant MAX_ELEMENTS_PRESALE = 444; // 444 Nipples for Pre Sale.
    uint256 private constant MAX_ELEMENTS_PREMINT = 30; // 30 Nipples for GiveAway.

    uint256 private constant MAX_MINT = 20; // Upper Limit per Mint is 20
    uint256 private constant MAX_MINT_PRESALE = 5; // Upper Limit per Mint is 5
    uint256 private constant MAX_MINT_PREMINT = 28; // Upper Limit per Mint is 28

    uint256 private _price;
    uint256 private _maxElements;
    uint256 private _maxMint;

    mapping(uint256 => bool) private _isOccupiedId;
    uint256[] private _occupiedList;

    mapping(address => bool) public _whitelist;
    bool private _isPresale;

    string private baseTokenURI;

    event NippleverseCreated(address to, uint256 indexed id);

    modifier saleIsOpen {
        if (_msgSender() != owner()) {
            require(SALE_OPEN == true, "SALES: Please wait a big longer before buying Nipples ;)");
        }
        require(_totalSupply() <= MAX_ELEMENTS, "SALES: Sale end");

        if (_msgSender() != owner()) {
            require(!paused(), "PAUSABLE: Paused");
        }
        _;
    }

    constructor (string memory baseURI) ERC721("Nippleverse", "NIP") {
        setBaseURI(baseURI);

        _price = PRICE_PREMINT;
        _maxElements = MAX_ELEMENTS_PREMINT;
        _maxMint = MAX_MINT_PREMINT;
    }

    function mint(address payable _to, uint256[] memory _ids) public payable saleIsOpen {
        uint256 total = _totalSupply();

        if (_isPresale == true) {
            require(_whitelist[_to] == true, "PRESALE: Only registered customers can mint!");
        }

        require(total + _ids.length <= _maxElements, "MINT: Current count exceeds maximum element count.");
        require(total <= _maxElements, "MINT: Please go to the Opensea to buy NippleVerse.");
        require(_ids.length <= _maxMint, "MINT: Current count exceeds maximum mint count.");

        if (_to != owner()) {
            require(msg.value >= price(_ids.length), "MINT: Current value is below the sales price of NippleVerse");
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            require(_isOccupiedId[_ids[i]] == false, "MINT: Those ids already have been used for other customers");
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            _mintAnElement(_to, _ids[i]);
        }
    }

    function _mintAnElement(address payable _to, uint256 _id) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _id);
        _isOccupiedId[_id] = true;
        _occupiedList.push(_id);

        emit NippleverseCreated(_to, _id);
    }

    function startPreSale() public onlyOwner {
        _isPresale = true;

        SALE_OPEN = true;

        _price = PRICE_PRESALE;
        _maxElements = MAX_ELEMENTS_PRESALE + MAX_ELEMENTS_PREMINT;
        _maxMint = MAX_MINT_PRESALE;
    }

    function startPublicSale() public onlyOwner {
        _isPresale = false;

        SALE_OPEN = true;

        _price = PRICE;
        _maxElements = MAX_ELEMENTS;
        _maxMint = MAX_MINT;
    }

    function flipSaleState() public onlyOwner {
        SALE_OPEN = !SALE_OPEN;
    }

    function addToWhitelist(address attender) public onlyOwner {
        _whitelist[attender] = true;
    }

    function removeFromWhitelist(address attender) public onlyOwner {
        _whitelist[attender] = false;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function price(uint256 _count) public view returns (uint256) {
        return _price.mul(_count);
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function occupiedList() public view returns (uint256[] memory) {
        return _occupiedList;
    }

    function maxMint() public view returns (uint256) {
        return _maxMint;
    }

    function maxSales() public view returns (uint256) {
        return _maxElements;
    }

    function maxSupply() public pure returns (uint256) {
        return MAX_ELEMENTS;
    }

    function raised() public view returns (uint256) {
        return address(this).balance;
    }

    function getTokenIdsOfWallet(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "WITHDRAW: No balance in contract");

        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "WITHDRAW: Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}