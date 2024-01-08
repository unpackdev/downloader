// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract CatsClub3D is ERC721Enumerable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 8888;
    uint256 public constant RESERVE_ELEMENTS = 20;
    uint256 public constant PRICE = 0.025 ether;
    uint256 public constant MAX_BY_MINT = 20;

    address public constant creatorAddress = 0x1473a8350b8f1ED87C7660B86005dd8E21cEabFF; // 35%
    address public constant devAddress = 0x7B65085F81fab2269524cbdb896Fe506Ec5E7D13;  // 35%
    address public constant charityAddress = 0x67a0CbA675015212517f092ee7760f6B86E6C8aA;  // 30%

    uint private startSales = 1630760400; // 2021-09-04 15:00:00

    string public baseTokenURI;

    event AdoptACat(uint256 indexed id);

    constructor(string memory baseURI) ERC721("3D Cats Club", "CC") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(block.timestamp >= startSales, "Sales not open");
        }
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
    function totalMint() public view returns (uint256) {
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
        emit AdoptACat(id + 1);
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

    function setStartSales(uint _start) public onlyOwner {
        startSales = _start;
    }

    function getStartSales() public view returns(uint) {
        return startSales;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(devAddress, balance.mul(35).div(100));
        _widthdraw(charityAddress, balance.mul(30).div(100));
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
        require(total + _count <= RESERVE_ELEMENTS, "Exceeded");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_msgSender());
        }
    }
}
