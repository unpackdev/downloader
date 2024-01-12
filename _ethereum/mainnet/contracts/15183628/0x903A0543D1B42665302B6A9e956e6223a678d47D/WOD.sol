// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract WOD is ERC721A, Ownable {

    //setup
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant tokenLimit = 10000;
    uint256 public presaleTokenLimit = 5252;
    uint256 public reservedForDevs = 300;

    uint256 public presalePriceETH = 200000000000000000;  //wei
    uint256 public priceETH = 250000000000000000; //wei

    uint256 public maxPerWallet = 50;
    uint256 public maxPerWalletPresale = 25;

    bool public publicSaleStarted = false;
    bool public presaleStarted = false;

    bool public revealed = false;
    string public notRevealedURI = "https://mint.wodnft.io/files/mint/prereveal.json";

    string public baseURI = "";

    mapping(address => uint256) private _walletMints;

    
    //constructor
    constructor() ERC721A("Women of Dichotomy", "WOD", 50, 10000) {
    }

    function currentPresalePrice() public view returns (uint256) {
        return presalePriceETH;
    }

    function currentPrice() public view returns (uint256) {
        return priceETH;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        if (!revealed) {
            return notRevealedURI;
        }
	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the presale preconditions aren't satisfied
    function presaleMint(uint256 tokens) external payable {
        require(presaleStarted, "Presale sale has not started");
        require(tx.origin == msg.sender, "Humans only please");
        require(tokens <= maxPerWalletPresale, "Cannot purchase this many tokens in a transaction");
        require(_walletMints[_msgSender()] + tokens <= maxPerWalletPresale, "Limit for this wallet reached");
        require(totalSupply() + tokens <= presaleTokenLimit, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(presalePriceETH * tokens <= msg.value, "ETH amount is incorrect");

        _walletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    function presaleCardMint(address toAddress, uint256 tokens) external payable {
        address crossmint_eth = 0xdAb1a1854214684acE522439684a145E62505233;
        require(
            msg.sender == crossmint_eth, // Optional Restriction
            "This function can be called by the Crossmint address only." // Error message
        );
        require(presaleStarted, "Presale sale has not started");
        require(tx.origin == msg.sender, "Humans only please");
        require(tokens <= maxPerWalletPresale, "Cannot purchase this many tokens in a transaction");
        require(_walletMints[toAddress] + tokens <= maxPerWalletPresale, "Limit for this wallet reached");
        require(totalSupply() + tokens <= presaleTokenLimit, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(presalePriceETH * tokens <= msg.value, "ETH amount is incorrect");

        _walletMints[toAddress] += tokens;
        _safeMint(toAddress, tokens);
    }

    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "Public sale has not started");
        require(tx.origin == msg.sender, "Humans only please");
        require(tokens <= maxPerWallet, "Cannot purchase this many tokens in a transaction");
        require(_walletMints[_msgSender()] + tokens <= maxPerWallet, "Limit for this wallet reached");
        require(totalSupply() + tokens <= tokenLimit, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(priceETH * tokens <= msg.value, "ETH amount is incorrect");

        _walletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    function cardMint(address toAddress, uint256 tokens) external payable {
        address crossmint_eth = 0xdAb1a1854214684acE522439684a145E62505233;
        require(
            msg.sender == crossmint_eth, // Optional Restriction
            "This function can be called by the Crossmint address only." // Error message
        );
        require(publicSaleStarted, "Presale sale has not started");
        require(tx.origin == msg.sender, "Humans only please");
        require(tokens <= maxPerWallet, "Cannot purchase this many tokens in a transaction");
        require(_walletMints[toAddress] + tokens <= maxPerWallet, "Limit for this wallet reached");
        require(totalSupply() + tokens <= tokenLimit, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(priceETH * tokens <= msg.value, "ETH amount is incorrect");

        _walletMints[toAddress] += tokens;
        _safeMint(toAddress, tokens);
    }

    //admin functions

    /// @param _newPresaleTokenLimit value to set
    function setPresaleTokenLimit(uint256 _newPresaleTokenLimit) external onlyOwner {
        presaleTokenLimit= _newPresaleTokenLimit;
    }

    /// @param _newReservedForDevs value to set
    function setReservedForDevs(uint256 _newReservedForDevs) external onlyOwner {
        if (_newReservedForDevs <= 300) {
            reservedForDevs = _newReservedForDevs;
        }
    }

    /// @param _newMaxPerWalletPresale value to set
    function setMaxPerWalletPresale(uint256 _newMaxPerWalletPresale) external onlyOwner {
        maxPerWalletPresale = _newMaxPerWalletPresale;
    }

    /// @param _newMaxPerWallet value to set
    function setMaxPerWallet(uint256 _newMaxPerWallet) external onlyOwner {
        maxPerWallet = _newMaxPerWallet;
    }

    function setPresalePrice(uint256 _newPrice) external onlyOwner {
        presalePriceETH = _newPrice;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        priceETH = _newPrice;
    }

    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _newNotRevealedURI) external onlyOwner {
        notRevealedURI = _newNotRevealedURI;
    }

    /// @dev reverts if any of the preconditions aren't satisfied
    function vaultMint(uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= tokenLimit, "Minting would exceed max supply");
        _safeMint(_msgSender(), tokens);
    }

    /// Distribute funds to wallet
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(_msgSender(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}