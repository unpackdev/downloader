// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract NAMES is ERC721Enumerable, Ownable, ReentrancyGuard {
    
    using Strings for uint256;

    uint256 public constant NMS_GIFT = 30;
    uint256 public constant NMS_PRESALE = 1000;
    uint256 public constant NMS_SALE = 8970;
    uint256 public constant NMS_MAX = NMS_GIFT + NMS_PRESALE + NMS_SALE;
    uint256 public constant NMS_MAX_PREMINT = 5;
    uint256 public constant NMS_MAX_MINT = 20;
    uint256 public NMS_PRICE = 0.03 ether;
    
    string private _contractURI;
    string private _baseTokenURI;
    address private _devAddress = 0xbb5670cbC61880b591a65b19116b3F8c107B8160;
    address private _artAddress = 0x5d3e4603d5885C16a8A0c410dB3F637EC4601eEB;

    uint256 public giftAmountMinted;
    uint256 public presaleAmountMinted;
    uint256 public saleAmountMinted;

    bool public presaleOn;
    bool public saleOn;
    
    event Minted(address minter, uint256 amount);

    constructor(string memory baseURI, string memory contURI) ERC721("NAMES", "NMS") {
        _baseTokenURI = baseURI;
        _contractURI = contURI;
    }
    
    function saleMint(uint256 amount) external payable nonReentrant {
        require(saleOn, "SALE_CLOSED");
        require(totalSupply() < NMS_MAX, "SOLDOUT");
        require(amount <= NMS_MAX_MINT, "EXCEED_NMS_PER_MINT");
        require(saleAmountMinted + amount <= NMS_SALE + NMS_PRESALE - presaleAmountMinted, "EXCEED_SALE");
        require(NMS_PRICE * amount <= msg.value, "INSUFFICIENT_ETH");
        
        for(uint256 i = 0; i < amount; i++) {
            saleAmountMinted++;
            _safeMint(msg.sender, totalSupply());
        }
        emit Minted (msg.sender, amount);
    }
    
    function presaleMint(uint256 amount) external payable nonReentrant {
        require(presaleOn, "PRESALE_CLOSED");
        require(totalSupply() < NMS_MAX, "SOLDOUT");
        require(amount <= NMS_MAX_PREMINT, "EXCEED_NMS_PER_MINT");
        require(presaleAmountMinted + amount <= NMS_PRESALE, "EXCEED_PRESALE");
        require(NMS_PRICE * amount <= msg.value, "INSUFFICIENT_ETH");
        
        for (uint256 i = 0; i < amount; i++) {
            presaleAmountMinted++;
            _safeMint(msg.sender, totalSupply());
        }
        emit Minted (msg.sender, amount);
    }
    
    function giftMint(address[] calldata receivers) external onlyOwner {
        require(giftAmountMinted + receivers.length <= NMS_GIFT, "EXCEED_GIFT");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            giftAmountMinted++;
            _safeMint(receivers[i], totalSupply());
        }
    }
    
    function togglePresale() external onlyOwner {
        presaleOn = !presaleOn;
    }
    
    function toggleSale() external onlyOwner {
        saleOn = !saleOn;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _baseTokenURI = URI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function setPrice(uint256 newPrice) external onlyOwner() {
        NMS_PRICE = newPrice;
    }
    
    function withdraw() external onlyOwner {
        payable(_devAddress).transfer(address(this).balance / 4);
        payable(_artAddress).transfer(address(this).balance / 3);
        payable(msg.sender).transfer(address(this).balance);
    }
    
}