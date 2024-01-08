// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
//import "./ReentrancyGuard.sol";
import "./Strings.sol";
//import "./Counters.sol";

interface NInterface {
    function balanceOf(address owner) external view returns (uint256);
}

interface MInterface {
    function balanceOf(address owner) external view returns (uint256);
}

contract LiveGeometricArt is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant EARLY_PRICE = 0.01 ether;
    uint256 public constant PRESALE_PRICE = 0.03 ether;
    uint256 public constant REGULAR_PRICE = 0.08 ether;
    
    
    bool private _saleIsActive = false;
    bool private _presaleIsActive = true;
    string public _baseURL = "ipfs://QmdCQ4df4Rk53mfygvMje7DK74buQtyX9H7M8r3Uxq8vmz/";
    
    address private _nAddr = 0x05a46f1E545526FB803FF974C790aCeA34D1f2D6;
    address private _mAddr = 0xb9178Ce2Ed2fC3bA9cbcB0aB2159b4c19e2A3C65;
    
    NInterface nContract = NInterface(_nAddr);
    MInterface mContract = MInterface(_mAddr);
    
    constructor() ERC721("Live Geometric Art", "LGA") Ownable() {}
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURL;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    
    function freeMint(uint256 amount) public {
        uint256 ts = totalSupply();
        require((ts + amount) < 101, "FREEMINT FINISHED");
        uint256 nmTokens = nContract.balanceOf(msg.sender) + mContract.balanceOf(msg.sender);
        uint256 ownedTokens = balanceOf(msg.sender);
        require((nmTokens - ownedTokens) >= amount, "AMOUNT EXCEEDED");
        
        for(uint256 i = 1; i <= amount; i++){
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function earlyBirdMint(uint256 amount) public payable {
        uint256 ts = totalSupply();
        require((ts + amount) < 501, "EARLY BIRD PRESALE FINISHED");
        uint256 nmTokens = nContract.balanceOf(msg.sender) + mContract.balanceOf(msg.sender);
        uint256 ownedTokens = balanceOf(msg.sender);
        require((nmTokens - ownedTokens) >= amount, "AMOUNT EXCEEDED");
        require(EARLY_PRICE * amount <= msg.value, "INSUFFICIENT ETH");
        
        for(uint256 i = 1; i <= amount; i++){
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    function presaleMint(uint256 amount) public payable {
        uint256 ts = totalSupply();
        require((ts + amount) < 6001, "PRESALE FINISHED");
        uint256 nmTokens = nContract.balanceOf(msg.sender) + mContract.balanceOf(msg.sender);
        uint256 ownedTokens = balanceOf(msg.sender);
        require((nmTokens - ownedTokens) >= amount, "AMOUNT EXCEEDED");
        require(PRESALE_PRICE * amount <= msg.value, "INSUFFICIENT ETH");
        
        for(uint256 i = 1; i <= amount; i++){
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    function mint(uint256 amount) public payable {
        uint256 ts = totalSupply();
        require(_saleIsActive, "PUBLIC SALE INACTIVE");
        require((ts + amount) < 12001, "SOLD OUT");
        require(REGULAR_PRICE * amount <= msg.value, "INSUFFICIENT ETH");
        
        for(uint256 i = 1; i <= amount; i++){
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function getPresaleActive() public view returns (bool) {
        return _presaleIsActive;
    }

    function getPublicSaleActive() public view returns (bool) {
        return _saleIsActive;
    }
    
    //admin
    function setPresaleActive(bool val) public onlyOwner {
        _presaleIsActive = val;
    }

    function setPublicSaleActive(bool val) public onlyOwner {
        _saleIsActive = val;
    }
    function setBaseURI(string memory url) onlyOwner public {
        _baseURL = url;
    }
    function getBaseURI() onlyOwner public view returns (string memory) {
        return _baseURL;
    }
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

