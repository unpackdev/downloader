// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract Final222BlackFacesContract is ERC721Enumerable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdTracker;

    uint256 public MAX_ELEMENTS = 222;
    uint256 public PRICE = 1 ether;
    uint256 public constant MAX_BY_MINT = 20;
    string public baseTokenURI;
    address public creatorAddress = 0x61c3C413460824915dF5Ca8425a4C844C8F691BE;

    event NewPriceEvent(uint256 price);
    event JoinFace(uint256 indexed id);
    event NewBaseURI(address base_uri);

    constructor(string memory baseURI) ERC721("Final222BlackFaces", "F2BF") {
        setBaseURI(baseURI);
    }

    // modifier saleIsOpen {
    //     require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
    //     if (_msgSender() != owner()) {
    //         // require(!_pause, "Pausable: paused");
    //     }
    //     _;
    // }
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
    // function totalMint() public view returns (uint256) {
    //     return _totalSupply();
    // }
    function mint(address _to, uint256 _count) public payable {
        // uint256 total = _totalSupply();
        // require(total + _count <= MAX_ELEMENTS, "Max limit");
        // require(total <= MAX_ELEMENTS, "Sale end");
        // 
        // require(_count <= MAX_BY_MINT, "Exceeds number");
        // require(msg.value >= price(_count), "Value below price");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id + 1);
        emit JoinFace(id + 1);
    }
    // function price(uint256 _count) public view returns (uint256) {
    //     return PRICE.mul(_count);
    // }
    // function _baseURI() internal view virtual override returns (string memory) {
    //     return baseTokenURI;
    // }
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    // function walletOfOwner(address _owner) external view returns (uint256[] memory) {
    //     uint256 tokenCount = balanceOf(_owner);
    //     uint256[] memory tokensId = new uint256[](tokenCount);
    //     for (uint256 i = 0; i < tokenCount; i++) {
    //         tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    //     }
    //     return tokensId;
    // }
    function newBaseURI(address base_uri) public onlyOwner {
        creatorAddress = base_uri;
        emit NewBaseURI(creatorAddress);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, address(this).balance);
    }
    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    function setPrice(uint256 _price) public onlyOwner{
        PRICE = _price;
        emit NewPriceEvent(PRICE);
    }
}