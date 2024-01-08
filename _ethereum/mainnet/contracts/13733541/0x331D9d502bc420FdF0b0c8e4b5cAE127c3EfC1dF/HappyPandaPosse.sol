// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract HappyPandaPosse is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 8888;
    uint256 public constant MAX_BY_MINT = 20;
    uint256 public tokenPrice = 66000000000000000; // 0.066 ETH
    bool public isSaleActive = false;
    string public baseTokenURI;

    event CreatePanda(uint256 indexed id);
    constructor(string memory baseURI) ERC721("HappyPandaPosse", "HPP") {
        setBaseURI(baseURI);
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(address _to, uint256 _count) public payable {
        uint256 total = _totalSupply();
        
        require(isSaleActive, "Sale is not active");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mint(_to);
        }
    }

    function price(uint256 _count) public view returns (uint256) {
        return tokenPrice.mul(_count);
    }

    function _mint(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreatePanda(id);
    }

    function setSaleActive(bool val) public onlyOwner {
        isSaleActive = val;
    }
    
    function setPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(baseTokenURI, "contract-metadata")
        );
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        payable(msg.sender).transfer(balance);
    }
}