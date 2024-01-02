// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721.sol";
import "./Ownable.sol";

contract NotFuckingLeaving is ERC721, Ownable {
    using Strings for uint256;

    mapping(address => bool) private whitelist;
    mapping(address => uint256) public mintCount;

    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public maxPerWallet;
    address public pool;

    string private _baseTokenURI;
    uint256 private _tokenIds;
    bool private publicOpen;

    constructor() ERC721("NotFuckingLeaving", "NFL") {
        mintPrice = 0.0069 ether;
        totalSupply = 6969;
        maxPerWallet = 10;
        pool = msg.sender;
        publicOpen = true;
        _baseTokenURI = "https://crimson-static-barnacle-945.mypinata.cloud/ipfs/QmQagyE1meCPYCdUbzvDv6VxjU8RmzGGtzuUCMUXo1UTNh/";
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function setMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    function setTotalSupply(uint256 _totalSupply) public onlyOwner {
        totalSupply = _totalSupply;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function updatePoolAddress(address newPool) public onlyOwner {
        pool = newPool;
    }

    function setPublicMint(bool _state) public onlyOwner {
        publicOpen = _state;
    }

    function mint(uint256 numberOfTokens) public payable {
        require(publicOpen, "Minting is not open to the public yet.");
        require(numberOfTokens > 0, "Must mint at least one token.");
        require(mintCount[msg.sender] + numberOfTokens <= maxPerWallet, "Exceeds max per wallet.");
        require(_tokenIds + numberOfTokens <= totalSupply, "Exceeds total supply.");
        require(msg.value >= mintPrice * numberOfTokens, "Not enough Ether sent.");

        if (!publicOpen){
            require(whitelist[msg.sender], "You are not whitelisted.");
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            mintCount[msg.sender]++;
            _tokenIds++;
            _safeMint(msg.sender, _tokenIds);
        }
    }


    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(pool).transfer(balance);
    }
}
