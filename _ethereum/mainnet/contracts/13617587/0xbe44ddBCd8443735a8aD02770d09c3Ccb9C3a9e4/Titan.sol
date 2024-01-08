//                        ROGUE TITANS                        
//
// MMMMMMXk;.;xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:':kNMMMMMM
// MMWXkl;.   .,lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMWXko;.   .;oOXWMM
// 0xc'.         ..:d0NMMMMMMMMMMMMMMMMMMMMN0xc'.         .'cxK
// .                 .,lkXWMMMMMMMMMMMMWXOo;.                 .
//                      .'cx0NMMMMMMWKxc'.                     
//                          .:kNNKOo;.                         
//          ;dc'.         .,cllc'..              ..:o;         
//         .lNWXOo;.   .;clc;.                .,lkXWNl.        
//         .lNMMMMN0dlllc,.               ..:d0NMMMMWl.        
//         .lNMMMMN0d:..               .,cllld0NMMMMNl.        
//         .lNWXkl,.                .;llc;..  .;okXWNl.        
//          ;o:..              .,;cllc,.         .'cd;         
//                          .;oONWNk:.                         
//                      .'cxKWMMMMMMN0xc'.                     
// .                 .;oOXWMMMMMMMMMMMMWXkl,.                 .
// Kxc'.         .'cxKWMMMMMMMMMMMMMMMMMMMMN0d:..         .'cd0
// MMWXOo;.   .;oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl,.   .,lkXWMM
// MMMMMMNk:':kXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx;.:kXMMMMMM
//                                                                                            
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721URIStorage.sol";

contract Titan is ERC721URIStorage, ReentrancyGuard, Ownable {

    event Activate();
    event Deactivate();
    event ActivatePresale();
    event DeactivatePresale();
    event Initialize();

    string public baseURI;
    bool public isSaleActive = false;

    // For epilogue usage
    uint256 constant public maxEpilogueMints = 10;
    uint256 public epiloguePointer = 0;

    // Airdrop mint parameters
    uint256 constant public maxAirdropTitans = 110;
    uint256 public numAirdroppedTitans = 0;

    // Standard mint parameters
    uint256 constant public maxTitans = 5555;
    uint256 public numMintedTitans = maxEpilogueMints;

    uint256 constant private mintPrice = 0.05 ether;
    uint16 constant private maxTitansPerMint = 5;

    // Whitelisted presale parameters
    bool public isWhitelistSaleActive = false;
    mapping (address => bool) public whitelistedWallets;

    constructor() ERC721("Rogue Titan", "TITAN") {
    }

    // Set a base URI
    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }
    
    // Get the base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // To be used to originally initliaze 
    function initializeSale(string memory baseURI_) public onlyOwner {
        require(!isSaleActive, "First disable Temple Minting to re-initialize.");

        baseURI = baseURI_;
        isWhitelistSaleActive = true;
        isSaleActive = false;

        emit Initialize();
    }

    // Toggle the main sale
    function toggleSale() public onlyOwner {
        isSaleActive = !isSaleActive;

        if (isSaleActive == true) {
            emit Activate();
        } else {
            emit Deactivate();
        }
    }

    // Toggle the whitelist presale
    function togglePresale() public onlyOwner {
        isWhitelistSaleActive = !isWhitelistSaleActive;

        if (isWhitelistSaleActive == true) {
            emit ActivatePresale();
        } else {
            emit DeactivatePresale();
        }
    }

    // Withdraw balance
    function withdrawBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Community mint for Titans
    function mintTitan(uint256 _numTitansToMint) external payable nonReentrant {
        require(isSaleActive, "Titans are not available to mint at this time.");
        require(_numTitansToMint > 0 && _numTitansToMint <= maxTitansPerMint, "You must mint between 1 and 5 Titans at a time.");
        require((numMintedTitans + _numTitansToMint) <= (maxTitans - maxAirdropTitans), "Requested value exceeds maximum value for Titans.");
       
        require(msg.value >= (_numTitansToMint * mintPrice), "Invalid amount of ETH sent.");

        if (isWhitelistSaleActive) {
            require(isAddressWhitelisted(msg.sender), "This address is not whitelisted for the presale.");
        }

        for (uint i = 0; i < _numTitansToMint; i++) {
            numMintedTitans++;
            _safeMint(msg.sender, numMintedTitans);
        }
    }

    // Owner airdrop for Titans
    function airdropTitans(address[] memory _airdropAddresses) external onlyOwner nonReentrant {
        require((numAirdroppedTitans + _airdropAddresses.length) <= maxAirdropTitans, "Requested value exceeds maximum value for Airdrop Titans.");
       
        for (uint256 i = 0; i < _airdropAddresses.length; i++) {
            numAirdroppedTitans++;
            numMintedTitans++;
            _safeMint(_airdropAddresses[i], numMintedTitans);
        }
    }

    // Add address' to the whitelist
    function addWhitelistAddresses(address[] memory _addresses) public onlyOwner { 
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistedWallets[_addresses[i]] = true;
        }
    }

    // Internal usage to verify address against whitelist
    function isAddressWhitelisted(address _address) public view returns (bool) {
        return whitelistedWallets[_address];
    }

    // For Epilogue usage only
    function mintEpilogueTitans(uint256 _numToMint) public onlyOwner nonReentrant {
        require((epiloguePointer + _numToMint) <= (maxEpilogueMints), "Requested value exceeds maximum value for Epilogue Titans.");

        for (uint i = 0; i < _numToMint; i++) {
            epiloguePointer++;
            _safeMint(msg.sender, epiloguePointer);
        }
    }
}
