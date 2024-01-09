// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract ToxicAwards is ERC1155, Ownable {

    string public contractMetadataUri = "https://storage.googleapis.com/toxicawards/contract_meta.json";

    mapping(uint => uint) public tokenSupplies;
    mapping(uint => uint) public tokenPrices;
    mapping(uint => bool) public isTokenPublic;

    mapping(uint => uint) public tokenMinted;

    mapping(address => uint) public walletFreeMints;
    uint public maxFreeMintsPerWallet = 50;

    constructor() ERC1155("https://storage.googleapis.com/toxicawards/meta/{id}") {
        configureAwardToken(0, 1 ether, 0, true);
        configureAwardToken(1, 30000, 0.01 ether, true);
        configureAwardToken(2, 10000, 0.02 ether, true);
        configureAwardToken(3, 5000, 0.05 ether, true);
        configureAwardToken(4, 1000, 0.2 ether, true);
    }

    function configureAwardToken(uint award, uint supply, uint price, bool isPublic) public onlyOwner {
        tokenSupplies[award] = supply;
        tokenPrices[award] = price;
        isTokenPublic[award] = isPublic;
    }

    // Setters region
    function setURI(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    function setContractMetadataUri(string calldata _contractMetadataURI) external onlyOwner {
        contractMetadataUri = _contractMetadataURI;
    }

    function setMaxFreeMintsPerWallet(uint _maxFreeMintsPerWallet) external onlyOwner {
        maxFreeMintsPerWallet = _maxFreeMintsPerWallet;
    }
    // End Setters region

    function sendToxicAwardTo(address account, uint award, uint amount) external payable {
        require(tokenSupplies[award] != 0, "Token does not exist");
        require(isTokenPublic[award], "You are not allowed to send this award");

        if (tokenPrices[award] == 0) {
            require(walletFreeMints[msg.sender] + amount <= maxFreeMintsPerWallet, "You used all your free mints");
            walletFreeMints[msg.sender] += amount;
        }

        require(amount > 0 && amount <= 10, "Too much mints for tx");
        require(tokenPrices[award] * amount == msg.value, "Wrong ethers count");
        require(tokenMinted[award] + amount <= tokenSupplies[award], "Award is out of limit");

        tokenMinted[award] += amount;
        _mint(account, award, amount, "");
    }

    function airdropAward(address[] calldata accounts, uint[] calldata awards, uint[] calldata amounts) external onlyOwner {
        require(accounts.length == awards.length && amounts.length == awards.length, "Bad args");
        for (uint i = 0; i < accounts.length; i++) {
            uint award = awards[i];
            uint amount = amounts[i];
            require(tokenMinted[award] + amount <= tokenSupplies[award], "Out of supply");
            tokenMinted[award] += amount;
            _mint(accounts[i], award, amount, "");
        }
    }



    // totalSupply for etherscan token tracker
    function totalSupply() external view returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < 100; i++) {
            sum += tokenMinted[i];
        }
        return sum;
    }

    // contract uri for correct 1155 opensea description
    function contractURI() public view returns (string memory) {
        return contractMetadataUri;
    }

    receive() external payable {

    }


    // withdraw
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(0xFeE836516a3Fc5f053F35964a2Bed9af65Da8159).transfer(balance * 7 / 100);
        payable(0xD84b0CC2deb9dcf87c0512B101105AD63a5E553a).transfer(balance * 7 / 100);
        payable(0x333F389B3044bEc989Df27d23beEBC7F973EE1D7).transfer(balance * 7 / 100);
        payable(0x28A0Eea8103C5B83CADD99E1C39b69FF1EbcC1d0).transfer(balance * 7 / 100);
        payable(0xA12EEeAad1D13f0938FEBd6a1B0e8b10AB31dbD6).transfer(balance * 2 / 100);
        payable(0xbFa306b0842135D62F48e350FE6B1c0A9F30ccdA).transfer(balance * 70 / 100);
    }
}