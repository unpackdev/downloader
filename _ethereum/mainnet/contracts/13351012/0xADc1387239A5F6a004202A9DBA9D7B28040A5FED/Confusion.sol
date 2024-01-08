//SPDX-License-Identifier: Unlicense

//
//    .'|=|`.     .'|=|  | `._|=|   |=|_.'      .'|=|_.'    .'|=|`.     .'|        .'|        .'|=|_.'   .'|=|  | |   | |   |
//  .'  | |  `. .'  | |  |      |   |         .'  |___    .'  | |  `. .'  |      .'  |      .'  |  ___ .'  | |  | `.  |_|  .'
//  |   |=|   | |   |=|.'       |   |         |   |`._|=. |   |=|   | |   |      |   |      |   |=|_.' |   |=|.'    `.   .'
//  |   | |   | |   |  |`.      `.  |         `.  |  __|| |   | |   | |   |  ___ |   |  ___ |   |  ___ |   |  |`.    |   |
//  |___| |___| |___|  |_|        `.|           `.|=|_.'' |___| |___| |___|=|_.' |___|=|_.' |___|=|_.' |___|  |_|    |___|
//
// @title: Confusion
// @author: Art Gallery

pragma solidity ^0.8.0;

import "./console.sol";

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract Confusion is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    bool private presale;
    bool private sale;

    uint256 public constant MAX_ITEMS = 2500;
    uint256 public constant PRICE = 0.06 ether;
    address public constant DEV_ADDRESS = 0x8A16dC2f80Fbcf8AbD9e3B9A5322ab9108d7431A;
    string public baseTokenURI;

    event CreateNft(uint256 indexed id);

    constructor(string memory baseURI) ERC721("CONFUSION", "CONFUSION") {
        setBaseURI(baseURI);
        presale = false;
        sale = false;
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ITEMS, "Sale ended");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mintReserve(uint256 _count, address _to) public onlyOwner {
        uint256 total = _totalSupply();
        require(total <= MAX_ITEMS, "Sale ended");
        require(total + _count <= MAX_ITEMS, "Max limit");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(sale == true, "Sale has not yet started");
        require(total <= MAX_ITEMS, "Sale ended");
        require(total + _count <= MAX_ITEMS, "Max limit");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function _mintAnElement(address _to) private {
        _tokenIdTracker.increment();
        uint id = _totalSupply();
        _safeMint(_to, id);
        emit CreateNft(id);
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function toggleSale() public onlyOwner {
        sale = !sale;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(DEV_ADDRESS, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success,) = _address.call{value : _amount}("");
        require(success, "Transfer failed.");
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
