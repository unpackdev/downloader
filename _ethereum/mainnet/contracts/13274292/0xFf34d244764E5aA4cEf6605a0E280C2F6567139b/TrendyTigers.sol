// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract TrendyTigers is ERC721Enumerable, Ownable {

    using Strings for uint256;

    uint256 public TT_GIFT = 99;
    uint256 public TT_PRIVATE = 900;
    uint256 public TT_PUBLIC = 9000;
    uint256 public TT_MAX = TT_GIFT + TT_PRIVATE + TT_PUBLIC;
    uint256 public TT_PER_MINT = 20;

    mapping(address => bool) public rareList;
    mapping(address => uint256) public rareListPurchases;

    string private _contractURI;
    string private _tokenBaseURI = "https://api.zinbucks.com/nft/TT/";
    address private _signerAddress = 0xc60112c3FB0AEbB86a835121EBDA43373eAC0f1d;

    uint256 public TT_PRICE = 0.03 ether;

    uint256 public giftedAmount;
    uint256 public publicAmountMinted;
    uint256 public privateAmountMinted;
    uint256 public presalePurchaseLimit = 20;
    bool public presaleLive;
    bool public saleLive;
    bool public locked;

    constructor() ERC721("Trendy Tigers", "TT") { }

    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }

    function addToRareList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!rareList[entry], "DUPLICATE_ENTRY");

            rareList[entry] = true;
        }
    }

    function removeFromRareList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");

            rareList[entry] = false;
        }
    }

    function buy(uint256 tokenQuantity) external payable {
        require(saleLive, "SALE_CLOSED");
        require(!presaleLive, "ONLY_PRESALE");
        require(totalSupply() < TT_MAX, "OUT_OF_STOCK");
        require(publicAmountMinted + tokenQuantity <= TT_PUBLIC, "EXCEED_PUBLIC");
        require(tokenQuantity <= TT_PER_MINT, "EXCEED_TT_PER_MINT");
        require(TT_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");

        for(uint256 i = 0; i < tokenQuantity; i++) {
            publicAmountMinted++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function presaleBuy(uint256 tokenQuantity) external payable {
        require(!saleLive && presaleLive, "PRESALE_CLOSED");
        require(rareList[msg.sender], "NOT_QUALIFIED");
        require(totalSupply() < TT_MAX, "OUT_OF_STOCK");
        require(privateAmountMinted + tokenQuantity <= TT_PRIVATE, "EXCEED_PRIVATE");
        require(rareListPurchases[msg.sender] + tokenQuantity <= presalePurchaseLimit, "EXCEED_ALLOC");
        require(TT_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            privateAmountMinted++;
            rareListPurchases[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= TT_MAX, "MAX_MINT");
        require(giftedAmount + receivers.length <= TT_GIFT, "GIFTS_EMPTY");

        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }

    function changePrice(uint256 price) external onlyOwner {
        TT_PRICE = price;
    }

    function reschedulePlan(uint256 gifts, uint256 presale, uint256 publicSale) external onlyOwner {
        TT_GIFT = gifts;
        TT_PRIVATE = presale;
        TT_PUBLIC = publicSale;
        TT_MAX = TT_GIFT + TT_PRIVATE + TT_PUBLIC;
    }

    function changePresalePurchaseLimit(uint256 limit) external onlyOwner {
        presalePurchaseLimit = limit;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function isPresaler(address addr) external view returns (bool) {
        return rareList[addr];
    }

    function presalePurchasedCount(address addr) external view returns (uint256) {
        return rareListPurchases[addr];
    }

    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }

    function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");

        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}
