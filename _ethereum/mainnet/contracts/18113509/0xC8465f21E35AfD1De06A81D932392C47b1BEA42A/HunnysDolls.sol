// SPDX-License-Identifier: MIT
// Creator: NFT Forge
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract HunnysDolls is ERC721A, Ownable {
    // The base link that leads to the image / video of the token
    string public baseTokenURI;

    // Starting and stopping sale and presale
    bool public active = true;

    // Price
    uint256 public price = 0.00 ether;

    // Hunnys wallet address for withdrawals
    address public hunnysWallet;

    constructor (string memory newBaseURI) ERC721A ("Hunnys Dolls", "HD") {
        setBaseURI(newBaseURI);
    }

    // TODO: start with index 1 instead of 0
    // 

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // See which address owns which tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        uint256 currentMatch = 0;

        if(tokenCount > 0) {
            for(uint256 i; i < supply; i++){
                address tokenOwnerAdd = ownerOf(i);
                if(tokenOwnerAdd == addr) {
                    tokensId[currentMatch] = i;
                    currentMatch = currentMatch + 1;
                }
            }
        }
        return tokensId;
    }

    // Public mint function
    function mintPublic(uint256 _amount) payable public {
        require( active,                       "Mint isn't active" );
        require( msg.value == price * _amount, "Wrong amount of ETH sent" );
        _safeMint( msg.sender, _amount );
    }

    // ADMIN FUNCTIONS

    // Admin mint function
    function mintOwner(uint256 _amount) public onlyOwner {
        _safeMint( msg.sender, _amount );
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // Start and stop public sale
    function setActive(bool val) public onlyOwner {
        active = val;
    }
    
    // Set a different public price in case ETH value changes
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // Set team addresses
    function setWalletAddress(address _address) public onlyOwner {
        hunnysWallet = _address;
    }

    // Withdraw funds from contract
    function withdrawTeam(uint256 amount) public payable onlyOwner {
        require(payable(hunnysWallet).send(amount));
    }
}