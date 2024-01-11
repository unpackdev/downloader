// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721A.sol";
//import "./ERC721.sol";
//import "./Counters.sol";
import "./Ownable.sol";

contract NFT is ERC721A, Ownable {
    //using Counters for Counters.Counter;
    //Counters.Counter private currentTokenId;
    uint256 private currentTokenId;
    string public baseTokenURI;
    address payable public walletRecipient;
    bool public publicMint;

    uint256 public constant TOTAL_SUPPLY = 1000;
    uint256 public constant MIN_VALUE = 10000000000000000; //0.010 ETH
    
    constructor() ERC721A("PootyHeads", "NFT") {
        baseTokenURI = "";
        walletRecipient = payable(0x165CD37b4C644C2921454429E7F9358d18A45e14);
        publicMint = false;
        currentTokenId = 0;
    }
    
    // Public mint function
    function mintTo(address recipient, uint256 qty)
        external payable
        returns (uint256)
    {
        require(publicMint || msg.sender == owner(), "Public mint is closed");
        require(currentTokenId+qty <= TOTAL_SUPPLY, "Max supply reached");
        require(msg.value >= MIN_VALUE*qty, "Min Ether value not reached (0.01 ETH each)");

        // MINT THE TOKEN
        currentTokenId += 1;
        //uint256 newItemId = currentTokenId;
        _safeMint(recipient, qty);

        // FORWARD ETH TO RECEIPIENT
        walletRecipient.transfer(msg.value);

        return currentTokenId-1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner{
        baseTokenURI = _baseTokenURI;
    }

    function setPublicMint(bool mintEnabled) external onlyOwner{
        publicMint = mintEnabled;
    }

    function setWallet(address payable wallet) external onlyOwner{
        walletRecipient = wallet;
    }

    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}

