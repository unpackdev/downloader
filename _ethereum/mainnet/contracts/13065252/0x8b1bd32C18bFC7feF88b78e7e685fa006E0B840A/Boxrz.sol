// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Boxrz is ERC721Enumerable, Ownable {
    uint256 private basePrice = 50000000000000000; //0.05
    uint256 private priceForThree = 45000000000000000; //0.045
    uint256 private priceForSix = 30000000000000000; //0.03

    //special sale bundles
    uint256 private packageThreeMax = 1111;
    uint256 private packageSixMax = 175;
    uint256 private packageThreeUsed = 0;
    uint256 private packageSixUsed = 0;

    uint256 private reserveAtATime = 25;
    uint256 private reservedCount = 0;
    uint256 private maxReserveCount = 200;
    address private MPAddress = 0xAa0D34B3Ac6420B769DDe4783bB1a95F157ddDF5;
    address private CoFounderAddress = 0x0654d160Da8EEA0Da28F4c58E110056C6d5FE93D;
    address private StaffAddress = 0x3eF31a7874cBB9b0b2C5c6B29206d06416F4D206;

    string _baseTokenURI;
    
    uint256 public constant MAX_MINTSUPPLY = 8888;
    bool public active = false;
    uint256 public maximumAllowedTokensPerPurchase = 25;
    
    event AssetMinted(uint256 tokenId, address sender);
    event SaleActivation(bool active);

    // Truth.
    constructor(string memory baseURI) ERC721("BOXRZ", "BXRZ") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        require(totalSupply() <= MAX_MINTSUPPLY, "Sale has ended.");
        _;
    }

     modifier onlyAuthorized() {
        require(MPAddress == msg.sender || owner() == msg.sender);
        _;
    }

    function setMaximumAllowedTokens(uint256 _count) public onlyAuthorized {
        maximumAllowedTokensPerPurchase = _count;
    }

    function setActive(bool val) public onlyAuthorized {
        active = val;
        emit SaleActivation(val);
    }
    
    function setReserveAtATime(uint256 val) public onlyAuthorized {
        reserveAtATime = val;
    }

    function setMaxReserve(uint256 val) public onlyAuthorized {
        maxReserveCount = val;
    }
    
    function setPrice(uint256 _price) public onlyAuthorized {
        basePrice = _price;
    }

    function setPriceForThree(uint256 _price) public onlyAuthorized {
        priceForThree = _price;
    }

    function setPriceForSix(uint256 _price) public onlyAuthorized {
        priceForSix = _price;
    }

    function setPackageThreeMax(uint256 _packageThreeMax) public onlyAuthorized {
        packageThreeMax = _packageThreeMax;
    }

    function setPackageSixMax(uint256 _packageSixMax) public onlyAuthorized {
        packageSixMax = _packageSixMax;
    }
    
    function setBaseURI(string memory baseURI) public onlyAuthorized {
        _baseTokenURI = baseURI;
    }

    function getMaximumAllowedTokens() public view onlyAuthorized returns (uint256) {
        return maximumAllowedTokensPerPurchase;
    }

    function getPrice() external view returns (uint256) {
        return basePrice; 
    }

    function getReserveAtATime() external view returns (uint256) {
        return reserveAtATime; 
    }

    function getPackageThreeMax() external view returns (uint256) {
        return packageThreeMax; 
    }

    function getPackageSixMax() external view returns (uint256) {
        return packageSixMax; 
    }
    
    function getPackageThreeUsed() external view returns (uint256) {
        return packageThreeUsed; 
    }

    function getPackageSixUsed() external view returns (uint256) {
        return packageSixUsed; 
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function getContractOwner() public view returns (address) {    
        return owner();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function reserveNft() public onlyAuthorized {
        require(reservedCount <= maxReserveCount, "Max Reserves taken already!");
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < reserveAtATime; i++) {
            emit AssetMinted(supply + i, msg.sender);
            _safeMint(msg.sender, supply + i);
            reservedCount++;
        }  
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        if (msg.sender != owner()) {
            require(active, "Sale is not active currently.");
        }
        
        require(totalSupply() + _count <= MAX_MINTSUPPLY, "Total supply exceeded.");
        require(totalSupply() <= MAX_MINTSUPPLY, "Total supply spent.");
        require(
            _count <= maximumAllowedTokensPerPurchase,
            "Exceeds maximum allowed tokens"
        );
        require(msg.value >= basePrice * _count, "Insuffient amount sent.");

        for (uint256 i = 0; i < _count; i++) {
            emit AssetMinted(totalSupply(), _to);
            _safeMint(_to, totalSupply());
        }
    }

    function mintThree(address _to) public payable saleIsOpen {
        if (msg.sender != owner()) {
            require(active, "Sale is not active currently.");
        }
        
        require(totalSupply() + 3 <= MAX_MINTSUPPLY, "Total supply exceeded.");
        require(totalSupply() <= MAX_MINTSUPPLY, "Total supply spent.");
        require(
            3 <= maximumAllowedTokensPerPurchase,
            "Exceeds maximum allowed tokens"
        );
        require(msg.value >= priceForThree * 3, "Insuffient amount sent.");
        require(packageThreeUsed <= packageThreeMax, "Max package sale count already!");

        for (uint256 i = 0; i < 3; i++) {
            emit AssetMinted(totalSupply(), _to);
            _safeMint(_to, totalSupply());
        }
        packageThreeUsed++;
    }

    function mintSix(address _to) public payable saleIsOpen {
        if (msg.sender != owner()) {
            require(active, "Sale is not active currently.");
        }
        
        require(totalSupply() + 6 <= MAX_MINTSUPPLY, "Total supply exceeded.");
        require(totalSupply() <= MAX_MINTSUPPLY, "Total supply spent.");
        require(
            6 <= maximumAllowedTokensPerPurchase,
            "Exceeds maximum allowed tokens"
        );
        require(msg.value >= priceForSix * 6, "Insuffient amount sent.");
        require(packageSixUsed <= packageSixMax, "Max package sale count taken already!");

        for (uint256 i = 0; i < 6; i++) {
            emit AssetMinted(totalSupply(), _to);
            _safeMint(_to, totalSupply());
        }
        packageSixUsed++;
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() external onlyAuthorized {
        uint balance = address(this).balance;
        payable(MPAddress).transfer(balance * 3500 / 10000);
        payable(CoFounderAddress).transfer(balance * 1800 / 10000);
        payable(StaffAddress).transfer(balance * 1500 / 10000);
        payable(owner()).transfer(address(this).balance);
    }
}


