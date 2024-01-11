// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";

contract CryptoBeavers is ReentrancyGuard, Ownable, ERC1155Supply {

    //Tier Configuration

    struct TierOne {
        uint256 tokenId;
        uint256 maxSupply;
        uint256 mintPrice;
        uint256 maxPerWallet;
    }

    struct TierTwo {
        uint256 tokenId;
        uint256 maxSupply;
        uint256 mintPrice;
        uint256 maxPerWallet;
    }

    struct TierThree {
        uint256 tokenId;
        uint256 maxSupply;
        uint256 mintPrice;
        uint256 maxPerWallet;
    }

    struct TierFour {
        uint256 tokenId;
        uint256 maxSupply;
        uint256 mintPrice;
        uint256 maxPerWallet;
    }

    struct TierFive {
        uint256 tokenId;
        uint256 maxSupply;
        uint256 mintPrice;
        uint256 maxPerWallet;
    }

    TierOne public tierOne;
    TierTwo public tierTwo;
    TierThree public tierThree;
    TierFour public tierFour;
    TierFive public tierFive;

    bool public isPublicMintActive;

    address public mattWallet; 
    address public paulWallet;

    constructor() payable ERC1155("ipfs://QmY2v1a4EwYz9GmJ3upBt1S43uJN6C6NcpVp8fpWJmw5MF/{id}.json") {

    tierOne = TierOne(0, 10, 1.5 ether, 1);
    tierTwo = TierTwo(1, 40, 0.75 ether, 2);
    tierThree = TierThree(2, 100, 0.3 ether, 5);
    tierFour =TierFour(3, 850, 0.1 ether, 15);
    tierFive =TierFive(4, 1000, 0.05 ether, 35);

    isPublicMintActive = true; 

    mattWallet = 0xA2bc07937aAC008829FCCd40b253Cf2629F48CDE; //Matt's Campaign Wallet
    paulWallet = 0x396A79d2eDEa70b00BE1ec25daDa7a0FFFd8A309; 

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Use your wallet to mint");
        _;
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function uri(uint256 _tokenid) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "ipfs://QmY2v1a4EwYz9GmJ3upBt1S43uJN6C6NcpVp8fpWJmw5MF/",
                Strings.toString(_tokenid),".json"
            )
        );
    }    

    //Minting

    function mintTierOne(uint256 quantity_) external payable nonReentrant callerIsUser {
        require(isPublicMintActive, 'minting not enabled');
        require(msg.value >= quantity_ * tierOne.mintPrice, 'wrong mint value');
        require(totalSupply(tierOne.tokenId) + quantity_ <= tierOne.maxSupply, 'exceeds max supply');
        require(balanceOf(msg.sender, tierOne.tokenId) + quantity_ <= tierOne.maxPerWallet, 'max per wallet reached');

        _mint(msg.sender, tierOne.tokenId, quantity_, "");
    }

    function mintTierTwo(uint256 quantity_) external payable nonReentrant callerIsUser {
        require(isPublicMintActive, 'minting not enabled');
        require(msg.value >= quantity_ * tierTwo.mintPrice, 'wrong mint value');
        require(totalSupply(tierTwo.tokenId) + quantity_ <= tierTwo.maxSupply, 'exceeds max supply');
        require(balanceOf(msg.sender, tierTwo.tokenId) + quantity_ <= tierTwo.maxPerWallet, 'max per wallet reached');

        _mint(msg.sender, tierTwo.tokenId, quantity_, "");
    }
    
    function mintTierThree(uint256 quantity_) external payable nonReentrant callerIsUser {
        require(isPublicMintActive, 'minting not enabled');
        require(msg.value >= quantity_ * tierThree.mintPrice, 'wrong mint value');
        require(totalSupply(tierThree.tokenId) + quantity_ <= tierThree.maxSupply, 'exceeds max supply');
        require(balanceOf(msg.sender, tierThree.tokenId) + quantity_ <= tierThree.maxPerWallet, 'max per wallet reached');

        _mint(msg.sender, tierThree.tokenId, quantity_, "");
    }

    function mintTierFour(uint256 quantity_) external payable nonReentrant callerIsUser {
        require(isPublicMintActive, 'minting not enabled');
        require(msg.value >= quantity_ * tierFour.mintPrice, 'wrong mint value');
        require(totalSupply(tierFour.tokenId) + quantity_ <= tierFour.maxSupply, 'exceeds max supply');
        require(balanceOf(msg.sender, tierFour.tokenId) + quantity_ <= tierFour.maxPerWallet, 'max per wallet reached');

        _mint(msg.sender, tierFour.tokenId, quantity_, "");
    }

    function mintTierFive(uint256 quantity_) external payable nonReentrant callerIsUser {
        require(isPublicMintActive, 'minting not enabled');
        require(msg.value >= quantity_ * tierFive.mintPrice, 'wrong mint value');
        require(totalSupply(tierOne.tokenId) + quantity_ <= tierFive.maxSupply, 'exceeds max supply');
        require(balanceOf(msg.sender, tierFive.tokenId) + quantity_ <= tierFive.maxPerWallet, 'max per wallet reached');

        _mint(msg.sender, tierFive.tokenId, quantity_, "");
    }                
   

    //Change Tier limitations
    function setTierOne(uint256 maxPerWallet_) external onlyOwner {
            tierOne.maxPerWallet = maxPerWallet_;
    }

    function setTierTwo(uint256 maxPerWallet_) external onlyOwner {
            tierTwo.maxPerWallet = maxPerWallet_;
    }

    function setTierThree(uint256 maxPerWallet_) external onlyOwner {
            tierThree.maxPerWallet = maxPerWallet_;
    }

    function setTierFour(uint256 maxPerWallet_) external onlyOwner {
            tierFour.maxPerWallet = maxPerWallet_;
    }

    function setTierFive(uint256 maxPerWallet_) external onlyOwner {
            tierFive.maxPerWallet = maxPerWallet_;
    }

    //Toggle Public mint status

    function setIsPublicMintActive() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    string private customContractURI = "ipfs://Qmdd5ocqCqpj9VqjC5Gb5v7PTKMZPtbURQQjcz4Cr3R497/";

    function setContractURI(string memory customContractURI_) external onlyOwner {
        customContractURI = customContractURI_;
    }

    function contractURI() public view returns (string memory) {
        return customContractURI;
    }

    //Withdraw shares to Matt and Paul

    function withdraw() external onlyOwner {
        uint256 _totalWithdrawal = address(this).balance;
        uint256 _totalWithdrawalShare = _totalWithdrawal / 5;
        
        uint256 _mattShare = _totalWithdrawalShare  * 4;
        uint256 _paulShare = _totalWithdrawal - _mattShare;

        (bool successMatt, ) = mattWallet.call{ value: _mattShare }('');
        require(successMatt, 'withdraw failed');
        (bool successPaul, ) = paulWallet.call{ value: _paulShare }('');
        require(successPaul, 'withdraw failed');
    }

}