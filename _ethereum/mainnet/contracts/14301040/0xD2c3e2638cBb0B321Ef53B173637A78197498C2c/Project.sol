// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
         __               __    ___   ___  _____  ____      
  /\/\  / _| ___ _ __    / /   / _ \ / __\/__   \/___ \ _   
 /    \| |_ / _ \ '__|  / /   / /_\//__\//  / /\//  / /| |_ 
/ /\/\ \  _|  __/ |    / /___/ /_\\/ \/  \ / / / \_/ /_   _|
\/    \/_|  \___|_|    \____/\____/\_____/ \/  \___,_\ |_|  
                                                            
*/

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

import "./console.sol";

contract mferslgbt is Ownable, ERC721A, ReentrancyGuard {
    bool publicSale = true;
    uint256 nbFree = 200;
    uint256 nbFreeDone = 0;

    constructor() ERC721A("mfers LGBTQ+", "LGBT", 20, 6969) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setFree(uint256 nb) external onlyOwner {
        nbFree = nb;
    }

    function freeMint(uint256 quantity) external callerIsUser onlyOwner {
        console.log("Quant :", quantity, ", nb done :", nbFreeDone);
        console.log("nb free:", nbFree);
        require(publicSale, "Public sale has not begun yet");
        require(nbFreeDone + quantity <= nbFree, "Reached max free supply");
        require(quantity <= 20, "can not mint this many free at a time");
        nbFreeDone += quantity;
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable callerIsUser {
        require(publicSale, "Public sale has not begun yet");
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        require(quantity <= 20, "can not mint this many at a time");
        require(
            0.0169 ether * quantity <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, quantity);
    }

    // metadata URI
    string private _baseTokenURI = "ipfs://QmS2Lno6K84u5jSXQCep2uhfGSuFG1b5RS6qxM8Wrv8SpA/";

    function initMint() external onlyOwner {
        _safeMint(msg.sender, 1); // As the collection starts at 0, this first mint is for the deployer ...
    }
    
    function setSaleState(bool state) external onlyOwner {
        publicSale = state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
    
}
