// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract xCny is Ownable, ERC721A {

    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable amountForPrivateAndDev;
    uint256 public immutable amountForDevs;
    uint256 public immutable collectionSize;

    struct SalePrice {
        uint64 privatePrice;
        uint64 publicPrice;
    }

    SalePrice public salePrice;

    bool public publicSaleIsActive = false;

    bool public uriIsFrozen = false;

    bool public permanentSaleLock = false;

    mapping(address => uint256) public allowlist;
    
    constructor(
        uint256 maxPerAddressDuringMint_,
        uint256 collectionSize_, 
        uint256 amountForPrivateAndDev_,
        uint256 amountForDevs_

    ) ERC721A("0xCNY", "CNY") {

        maxPerAddressDuringMint = maxPerAddressDuringMint_;
        amountForPrivateAndDev = amountForPrivateAndDev_;
        amountForDevs = amountForDevs_;
        collectionSize = collectionSize_;
        require(
            amountForPrivateAndDev_ <= collectionSize_,
            "Collection size is too small."
        );
    }

    function setSalePrice(uint64 _privatePrice, uint64 _publicPrice) external onlyOwner {
        salePrice.privatePrice = _privatePrice;
        salePrice.publicPrice = _publicPrice;
    }

    function changeToPublicSale() external onlyOwner {
        switchPublicSaleState();
        salePrice.privatePrice = 0;
    }

    function lockSales() external onlyOwner {
        require(publicSaleIsActive, "Public sale is not active to lock");
        publicSaleIsActive = false;
        permanentSaleLock = true;
    }

    function switchPublicSaleState() public onlyOwner {
        require(!permanentSaleLock, "Sale is locked");
        publicSaleIsActive = !publicSaleIsActive;
    }

    function publicSaleMint(uint256 quantity) external payable {
        uint256 price = uint256(salePrice.publicPrice);
        require(publicSaleIsActive,
        "Public sale is not active");
        require(totalSupply() + quantity <= collectionSize,
        "Not enough supply left to support the desired mint amount");
        require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
        "Unable to mint so many");
        _safeMint(msg.sender, quantity);
        refundIfOver(price * quantity);
    }

    function privateSaleMint() external payable {
        uint256 price = uint256(salePrice.privatePrice);
        require(price != 0, "Private sale is not active");
        require(allowlist[msg.sender] > 0, "User is not eligible for private mint");
        require(
            totalSupply() + 1 <= amountForPrivateAndDev,
            "Not enough reserved left for the private sale");
        allowlist[msg.sender]--;
        _safeMint(msg.sender, 1);
        refundIfOver(price);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Did not pay enough ETH.");
        if(msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function teamMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= amountForDevs,
            "Too many minted for the team mint.");
        uint256 maxBatchSize = 6;
        require(quantity % maxBatchSize == 0, "Must mint in multiple of 6");
        uint256 numBatches = quantity / maxBatchSize;
        for(uint256 i = 0; i < numBatches; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    function addAllowList(address[] memory addresses) public onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = 1;
        }
    }

    // //metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    address private ADDRESS_ONE = 0x5e8A167ac4c5d230C37a6F8F2DAdff3D3153F023;
    address private ADDRESS_TWO = 0x99c71E83955426226e52Dc94A67DbE1d396F2A4f;
    address private ADDRESS_THREE = 0x0c47F18383622f04349BE34870fc2960595591fe;

    function withdrawMoney() external {

        uint256 balance = address(this).balance;

        uint256 balCut = balance * 25/100;

        payable(ADDRESS_ONE).transfer(balCut);
        payable(ADDRESS_TWO).transfer(balCut);
        payable(ADDRESS_THREE).transfer(address(this).balance);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

}