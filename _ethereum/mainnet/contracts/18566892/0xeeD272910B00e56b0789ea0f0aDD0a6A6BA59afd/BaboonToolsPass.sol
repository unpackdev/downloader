// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

// 
// After you've chosen from one of 50 snipers, then what? Find your edge, Ape like a baboon.
// 
// X: https://x.com/baboontools
// Telegram: https://t.me/baboontools
//
contract BaboonToolsPass is ERC721, ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    constructor() ERC721("Baboon Tools Pass", "BTOOLSPASS") {
        nextTokenId = nextTokenId.add(1);
    }
    
    uint256 public constant MAX_SUPPLY = 150; // whitelist + free mints + public

    uint256 public price = 0.5 ether;

    bool public isMintActive = false;

    bool public isWhitelistActive = true;

    mapping(address => bool) public whitelist;

    mapping(address => bool) public freeMintWhitelist;

    uint256 private nextTokenId;

    string private tokenBaseURI;

    event PriceChanged(uint256 indexed price);

    function mint() external nonReentrant payable {
        require(isMintActive, "Minting did not start");
        require(totalSupply().add(1) <= MAX_SUPPLY, "Exceeds max supply");
        require(freeMintWhitelist[msg.sender] || price == msg.value, "Ether value sent is not correct");
        require(!isWhitelistActive || whitelist[msg.sender] || freeMintWhitelist[msg.sender], "Public minting did not start");

        if (isWhitelistActive) {
            whitelist[msg.sender] = false;
        }

        if (freeMintWhitelist[msg.sender]) {
            freeMintWhitelist[msg.sender] = false;
        }

        _safeMint(msg.sender, nextTokenId); 
        nextTokenId = nextTokenId.add(1);
    }
    
    function addWhitelist(address[] calldata addresses, bool isWhitelisted) onlyOwner external {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = isWhitelisted;
        }
    }

    function addFreeMintWhitelist(address[] calldata addresses, bool isWhitelisted) onlyOwner external {
        for (uint256 i = 0; i < addresses.length; i++) {
            freeMintWhitelist[addresses[i]] = isWhitelisted;
        }
    }

    function toggleMint() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function toggleWhitelist() external onlyOwner {
        isWhitelistActive = !isWhitelistActive;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        emit PriceChanged(_price);
    }

    function withdraw() onlyOwner public {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }    

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function setTokenBaseURI(string memory _tokenBaseURI) public onlyOwner {
        tokenBaseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}