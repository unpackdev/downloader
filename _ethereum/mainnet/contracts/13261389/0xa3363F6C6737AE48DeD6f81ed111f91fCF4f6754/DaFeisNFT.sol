// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract DaFeisNFT is ERC721Enumerable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 10000;
    uint256 public constant PRICE = 33 * 10**15;
    uint256 public constant MAX_BY_MINT = 20;
    address public constant creatorAddress = 0x49E6c500062631dE1d79d773436831D1D1b4eE5e;
    // address public constant devAddress = 0xcBCc84766F2950CF867f42D766c43fB2D2Ba3256;
    string public baseTokenURI;
    bool private _pause;

    event JoinFace(uint256 indexed id);

    constructor(string memory baseURI) ERC721("DaFeisNFT", "DFN") {
        setBaseURI(baseURI);
        pause(true);
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!_pause, "Pausable: paused");
        }
        _;
    }
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function totalMint() external view returns (uint256) {
        return _totalSupply();
    }
    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");
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
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }    
    function pause(bool val) public onlyOwner {
        _pause = val;
    }
    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        // _widthdraw(devAddress, balance.mul(25).div(100));
        _widthdraw(creatorAddress, address(this).balance);
    }
    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
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

    function reserve(uint256 _count) public onlyOwner {
        uint256 total = _totalSupply();
        require(total + _count <= 100, "Exceeded");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_msgSender());
        }
    }
}