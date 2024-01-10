//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

/*
  __  __  ____  _      ____  _  _________          _______ ______ 
 |  \/  |/ __ \| |    / __ \| |/ /_   _\ \        / /_   _|  ____|
 | \  / | |  | | |   | |  | | ' /  | |  \ \  /\  / /  | | | |__   
 | |\/| | |  | | |   | |  | |  <   | |   \ \/  \/ /   | | |  __|  
 | |  | | |__| | |___| |__| | . \ _| |_   \  /\  /   _| |_| |____ 
 |_|  |_|\____/|______\____/|_|\_\_____|   \/  \/   |_____|______|   
                                  
*/

contract Molokiwie is ERC721Enumerable, Ownable {
    uint256 public cost;
    bool public paused;
    string public tokenURIPrefix;
    string public contractURIPrefix;

    constructor() ERC721("MOLOKIWIE", "MOLOKIWIE") 
    {
        pause(false);
        setCost(20000000 gwei); //0.02 eth
        setTokenURI("https://gateway.pinata.cloud/ipfs/QmPhtzrqnJ6ozr98JbVxWvac4anj6ViQeaCwTHBuAYmQU3");
        setContractURI("https://gateway.pinata.cloud/ipfs/QmR6cvG9F35yRKRn8QPfRX8cGhm3Ez27E3Z7uEu1jdTBVt");
    }

    function mint(uint256 _mintAmount) public payable 
    {
        require(canMint(_mintAmount, msg.value), "Can't mint");
        uint256 supply = totalSupply();
        for(uint i; i < _mintAmount; ++i ) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function canMint(uint256 _mintAmount, uint256 ethValue) public view returns (bool) {
        require(!paused, "Minting is paused");
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        require(ethValue >= cost * _mintAmount, "Insufficient funds");
        
        return true;
    }

    function setTokenURI(string memory _tokenURIPrefix) public onlyOwner {
        tokenURIPrefix = _tokenURIPrefix;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return tokenURIPrefix;
    }

    function setContractURI(string memory _contractURIPrefix) public onlyOwner {
        contractURIPrefix = _contractURIPrefix;
    }

    //https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return contractURIPrefix;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os, "Can't withdraw");
    }
}
