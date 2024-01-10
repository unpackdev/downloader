// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./ERC721.sol";

contract HuxleyLago is ERC721, Ownable {
        
    uint256 public tokenId;
    uint256 public maxSupply;
    string public baseURI;    
    
    /// @dev Initializes the contract by setting a `name` and a `symbol` to the token.    
    constructor(uint256 _maxSupply, string memory _baseURI) ERC721("HUXLEY x LAGO", "HUXLAGO") {
        maxSupply = _maxSupply;        
        baseURI = _baseURI;
        tokenId = 0;
    }

     /// @dev Batch mint tokens. 
     function privateMintBatch(uint256 _amountToMint, address _to) external onlyOwner {
        require(_amountToMint > 0, "HL: amount is 0");
        require(_amountToMint + tokenId <= maxSupply, "HL: exceeds max supply");
        for (uint256 i = 1; i <= _amountToMint; i++) {
            tokenId++;            
            _safeMint(_to, tokenId);
        }
    }

    /// @dev Returns URI for the token. Each Issue number has a base uri.
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "HL: invalid token");
        return baseURI;
    }

      
    /// @dev Set baseURI.          
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;        
    }

}