// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract PolyversePass is ERC721, ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    constructor() ERC721("Polyverse Pass", "POLYVERSEPASS")
    {
        nextTokenId = nextTokenId.add(1);
    }
    
    uint256 public constant MAX_SUPPLY = 999;

    uint256 public price = 0.3333 ether;

    bool public saleIsActive = false;

    mapping(address => bool) public whitelist;

    mapping(address => bool) public freeMintWhitelist;

    uint256 private nextTokenId;

    string private tokenBaseURI;

    event PriceChanged(uint256 indexed price);

    function mint() external nonReentrant payable {
        require(saleIsActive, "Sale did not start");
        require(totalSupply().add(1) <= MAX_SUPPLY, "Exceeds max supply");
        require(price == msg.value, "Ether value sent is not correct");
        require(whitelist[msg.sender], "Not enough allowance");

        whitelist[msg.sender] = false;

        _safeMint(msg.sender, nextTokenId); 
        nextTokenId = nextTokenId.add(1);
    }

    function freeMint() external nonReentrant {
        require(saleIsActive, "Sale did not start");
        require(totalSupply().add(1) <= MAX_SUPPLY, "Exceeds max supply");
        require(freeMintWhitelist[msg.sender], "Not whitelisted for free mint");

        freeMintWhitelist[msg.sender] = false;

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

    function toggleSale() external onlyOwner {
        saleIsActive = !saleIsActive;
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