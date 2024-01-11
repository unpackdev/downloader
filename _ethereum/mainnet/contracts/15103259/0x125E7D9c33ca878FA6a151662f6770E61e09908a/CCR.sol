// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract CrustyCumRags is ERC721A, Ownable {
    using Strings for uint;

    uint public constant SUPPLY = 3328; 
    uint public tokenLimit = 2; 
    string public baseURI = "ipfs://QmXPnqtfLkC2Z9RPmUzFwGCEk17MthunEL2M7sxhdCvAFk/";
    bool public paused = true;

    constructor() ERC721A("Crusty Cum Rags", "CUM") {}
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice Sets the base URI for the tokens
    /// @param newURI the URI to set
    function setBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }
    
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    /// @notice Update current sale stage
    function flipPaused() external onlyOwner {
        paused = !paused;
    }
    
    /// @notice Withdraw contract's balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        payable(owner()).transfer(balance);
    }

    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(totalSupply() + count <= SUPPLY, "Supply exceeded");
        _safeMint(to, count);
    }

    /// @notice Get token's URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "tokenId doesn't exist yet");

        string memory baseURI_mem = _baseURI();
        return bytes(baseURI_mem).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /// @param quantity quantity to mint
    function mint(uint256 quantity) external {
        require(!paused, "Minting paused");
        require(quantity <= tokenLimit, "2 max per mint");
        require(totalSupply() + quantity <= SUPPLY, "Supply exceeded");
        require(quantity + _numberMinted(msg.sender) <= tokenLimit, "Token limit reached");

        _safeMint(msg.sender, quantity);
    }
}