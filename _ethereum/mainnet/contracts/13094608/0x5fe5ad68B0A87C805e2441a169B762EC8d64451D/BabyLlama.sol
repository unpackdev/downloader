// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BabyLlama is ERC721Enumerable, Ownable {
    
    uint256 public constant GIFT_LLAMA = 77;
    uint256 public constant COMMUNITY_LLAMA = 200;
    uint256 public constant PRE_LLAMA = 500;
    uint256 public constant ADOPT_LLAMA = 7000;
    uint256 public constant MAX_LLAMA = ADOPT_LLAMA + PRE_LLAMA + COMMUNITY_LLAMA + GIFT_LLAMA;

    uint256 private _price = 0.05 ether;
    string private _baseTokenURI;
    bool private _adoptForCommunityOpen = false;
    bool private _preAdoptOpen = false;
    bool private _adoptOpen = false;

    address private daddy = 0xeaEA8dA383cd986468726a656C3be67b8d123FbB;

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        setBaseURI(baseURI);
        transferOwnership(daddy);
    }

    function adoptForCommunity(uint256 num) public onlyOwner {
        uint256 adopted = totalSupply();
        require(num + adopted <= GIFT_LLAMA, "You can not exceed over 77");
        for (uint256 i; i < num; i++) {
            _safeMint(owner(), adopted + i);
        }
    }

    function communityAdopt(uint256 num) public payable {
        uint256 adopted = totalSupply();
        require(_adoptForCommunityOpen, "not available for community exclusive sale");
        require(msg.value == _price * num, "invalid value");
        require(adopted + num <= GIFT_LLAMA + COMMUNITY_LLAMA, "You can not exceed over 277");
        require(num <= 2, "2 is the maximum");
        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, adopted + i);
        }
        withdraw();
    }

    function preAdopt(uint256 num) public payable {
        uint256 adopted = totalSupply();
        require(_preAdoptOpen, "not available for pre sale");
        require(msg.value == _price * num, "invalid value");
        require(adopted + num <= GIFT_LLAMA + COMMUNITY_LLAMA + PRE_LLAMA, "You can not exceed over 777");
        require(num <= 5, "5 is the maximum");
        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, adopted + i);
        }
        withdraw();
    }

    function adopt(uint256 num) public payable {
        uint256 adopted = totalSupply();
        require(_adoptOpen, "not available for public sale");
        require(msg.value == _price * num, "invalid value");
        require(adopted + num <= MAX_LLAMA, "You can not exceed over 7777");
        require(num <= 20, "20 is the maximum");
        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, adopted + i);
        }
        withdraw();
    }

    function startCommunityAdopt() public onlyOwner {
        require(!_adoptForCommunityOpen,"community exclusive sale is already in progress.");
        _adoptForCommunityOpen = true;
    }

    function startPreAdopt() public onlyOwner {
        require(!_preAdoptOpen, "pre sale is already in progress.");
        _preAdoptOpen = true;
    }

    function startAdopt() public onlyOwner {
        require(!_adoptOpen, "public sale is already in progress.");
        _adoptOpen = true;
    }

    function closeAdopt() public onlyOwner {
        _adoptForCommunityOpen = false;
        _preAdoptOpen = false;
        _adoptOpen = false;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function price() public view returns (uint256) {
        return _price;
    }

    function updatePrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() public payable {
        require(payable(owner()).send(address(this).balance));
    }
}
