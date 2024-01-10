//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./console.sol";

interface IPirates {
    function mint(uint256 _amount, address recipient) external;
}

contract PiratesMinter is Ownable {

    ERC721 blootMF;
    ERC721 soda;
    ERC721 bloot;
    ERC721 avp;
    IPirates pirates;
    
    uint256 freeMintCounter = 0;
    uint256 discountMintCounter = 0;
    uint256 fullPriceMintCounter = 0;
    uint256 publicLimit = 1800;
    uint256 maxTotalMint = 2000;

    uint256 defaultPrice = 0.05 ether;
    uint256 discountPrice = 0.04 ether;

    mapping(address => bool) private freeMintWhitelist;
    mapping(address => bool) private freeMintUsed;
    mapping(address => uint256) private freeMintMultiples;

    mapping(address => uint256) private discountMintMap;
    mapping(address => uint256) private fullPriceMintMap;
    address[] discountMinters;
    address[] fullPriceMinters;

    bool pausedFreeMint;
    bool pausedDiscountMint;
    bool pausedFullPriceMint;

    constructor() {

    }

    function isWhitelisted(address _address) public view returns (bool) {
        return freeMintWhitelist[_address];
    }

    function getWhitelistMultiple(address _address) public view returns (uint256) {
        return freeMintMultiples[_address];
    }

    function hasUsedWhitelist(address _address) public view returns (bool) {
        return freeMintUsed[_address];
    }

    function getDiscountMinters() external view returns (address[] memory) {
        return discountMinters;
    }

    function getFullPriceMinter() external view returns (address[] memory) {
        return fullPriceMinters;
    }

    function getDiscountMintCountForAddress(address _address) external view returns (uint256) {
        return discountMintMap[_address];
    }

    function getFullPriceMintCountForAddress(address _address) external view returns (uint256) {
        return fullPriceMintMap[_address];
    }

    function getFreeMintCounter() external view returns (uint256) {
        return freeMintCounter;
    }

    function getDiscountMintCounter() external view returns (uint256) {
        return discountMintCounter;
    }

    function getFullPricerMintCounter() external view returns (uint256) {
        return fullPriceMintCounter;
    }

    function getTotalMinted() external view returns (uint256) {
        return freeMintCounter + discountMintCounter + fullPriceMintCounter;
    }

    function getPublicLimit() external view returns (uint256) {
        return publicLimit;
    }

    function getMaxTotalMint() external view returns (uint256) {
        return maxTotalMint;
    }

    function getPausedFreeMint() external view returns (bool) {
        return pausedFreeMint;
    }

    function getPausedDiscountMint() external view returns (bool) {
        return pausedDiscountMint;
    }

    function getPausedFullPriceMint() external view returns (bool) {
        return pausedFullPriceMint;
    }

    // Setters

    function setPausedFreeMint(bool _value) external onlyOwner {
        pausedFreeMint = _value;
    }

    function setPausedDiscountMint(bool _value) external onlyOwner {
        pausedDiscountMint = _value;
    }

    function setPausedFullPriceMint(bool _value) external onlyOwner {
        pausedFullPriceMint = _value;
    }

    function setPublicLimit(uint256 _limit) external onlyOwner {
        publicLimit = _limit;
    }

    function setBlootMF(address _address) external onlyOwner {
        blootMF = ERC721(_address);
    }

    function setSoda(address _address) external onlyOwner {
        soda = ERC721(_address);
    }

    function setBloot(address _address) external onlyOwner {
        bloot = ERC721(_address);
    }

    function setAVP(address _address) external onlyOwner {
        avp = ERC721(_address);
    }

    function setPirates(address _piratesAddress) external onlyOwner {
        pirates = IPirates(_piratesAddress);
    }

    function setDefaultPrice(uint256 _price) external onlyOwner {
        defaultPrice = _price;
    }

    function addToFreeWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            freeMintWhitelist[_addresses[i]] = true;
        }
    }

    function addFreeWhitelistMultiples(
        address[] memory _addresses,
        uint256[] memory _multiples
    ) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            freeMintMultiples[_addresses[i]] = _multiples[i];
        }
    }

    // Manage Sale

    // Mint
    function mint(uint256 amount) external payable {

        require(
            fullPriceMintCounter + discountMintCounter < publicLimit, "Public mint limit reached"
        );

        require(
            msg.value == amount * defaultPrice,
            "Purchase: Incorrect payment"
        );

        address recipient = msg.sender;
        console.log("piratesMinter.mint: recipient", recipient);
        pirates.mint(amount, recipient);
        fullPriceMintCounter += amount;
        fullPriceMintMap[msg.sender] += amount;
        fullPriceMinters.push(msg.sender);
    }

    function discountMint(uint256 amount) external payable {
        console.log("discountMint", amount);

        require(
            fullPriceMintCounter + discountMintCounter < publicLimit, "Public mint limit reached"
        );
        
        require(
            blootMF.balanceOf(msg.sender) > 0 ||
            soda.balanceOf(msg.sender) > 0 ||
            bloot.balanceOf(msg.sender) > 0 ||
            avp.balanceOf(msg.sender) > 0,
            "sender doesn't have an NFT from a collection that entitles to discount"
        );
        
        require(
            msg.value == amount * discountPrice,
            "Purchase: Incorrect payment"
        );

        pirates.mint(amount, msg.sender);
        discountMintCounter += amount;
        discountMintMap[msg.sender] += amount;
        discountMinters.push(msg.sender);
    }

    function freeMint() external {
        require(freeMintWhitelist[msg.sender] == true,  "sender is not on free whitelist");
        require(freeMintUsed[msg.sender] == false,      "sender has already used free whitelist");
        uint256 amount = freeMintMultiples[msg.sender] == 0 ? 1 : freeMintMultiples[msg.sender];
        freeMintUsed[msg.sender] = true;
        pirates.mint(amount, msg.sender);
        freeMintCounter += amount;
    }

    // Withdraw

    function withdraw() public payable onlyOwner {
        uint256 bal = address(this).balance;
        require(payable(msg.sender).send(bal));
    }

    function withdrawToken(address _tokenAddress) public payable onlyOwner {
        ERC20 token = ERC20(_tokenAddress);
        uint256 bal = token.balanceOf(address(this));
        token.transfer(msg.sender, bal);
    }
}
