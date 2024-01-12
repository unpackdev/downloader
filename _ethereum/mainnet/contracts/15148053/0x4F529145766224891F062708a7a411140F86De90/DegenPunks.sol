// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract DegenPunks is ERC721A, Ownable {
    bool public paused = true;
    uint public constant tokenSupply = 2311; 
    uint public tokensPerUser = 2; 
    string public baseURI = "ipfs://QmSMF2sba5wJgrTuE39MAUavJDnFthSrgbSw71mt7G4fcM/";
    

    constructor() ERC721A("Degen Punks", "DEGEN") {}

    /// @param quantity Number to mint
    function mint(uint256 quantity) external {
        require(!paused, "Minting paused");
        require(quantity <= tokensPerUser, "2 or less per mint");
        require(totalSupply() + quantity <= tokenSupply, "Supply exceeded");
        require(quantity + _numberMinted(msg.sender) <= tokensPerUser, "Cannot mint more than 2");
        _safeMint(msg.sender, quantity);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function flipPaused() external onlyOwner {
        paused = !paused;
    }
    
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "tokenId doesn't exist yet");

        string memory baseURI_mem = _baseURI();
        return bytes(baseURI_mem).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : "";
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        payable(owner()).transfer(balance);
    }

    function airdrop(address to, uint count) external onlyOwner {
        require(totalSupply() + count <= tokenSupply, "Supply exceeded");
        _safeMint(to, count);
    }
}