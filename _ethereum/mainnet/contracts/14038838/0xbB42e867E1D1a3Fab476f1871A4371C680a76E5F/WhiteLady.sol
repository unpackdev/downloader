// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/**
 ____      ____  __        _   _           _____                  __           
|_  _|    |_  _|[  |      (_) / |_        |_   _|                |  ]          
  \ \  /\  / /   | |--.   __ `| |-'.---.    | |      ,--.    .--.| |   _   __  
   \ \/  \/ /    | .-. | [  | | | / /__\\   | |   _ `'_\ : / /'`\' |  [ \ [  ] 
    \  /\  /     | | | |  | | | |,| \__.,  _| |__/ |// | |,| \__/  |   \ '/ /  
     \/  \/     [___]|__][___]\__/ '.__.' |________|\'-;__/ '.__.;__][\_:  /   
                                                                      \__.'    
 */

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract TheWhiteLady is Ownable, ERC721A, ReentrancyGuard {
    bool publicSale = true;
    uint256 nbFree = 444;

    constructor() ERC721A("The White Lady", "WLADY", 20, 4445) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setFree(uint256 nb) external onlyOwner {
        nbFree = nb;
    }

    function freeMint(uint256 quantity) external callerIsUser {
        require(publicSale, "Public sale has not begun yet");
        require(totalSupply() + quantity <= nbFree, "Reached max free supply");
        require(quantity <= 3, "can not mint this many free at a time");
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
            0.025 ether * quantity <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, quantity);
    }

    // metadata URI
    string private _baseTokenURI =
        "ipfs://QmTV6iecdR5VRf6VCvxUtTrtxqyBrTsmrEqonv8noWbq7F/";

    function initMint() external onlyOwner {
        _safeMint(msg.sender, 1); // As the collection starts at 0, this first mint is for the deployer ...
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
