// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";

contract NonFungibleHeroesLegendaryCollection is ERC721Enumerable, Ownable {
    uint256 public constant MAX_TOKENS = 101;   

    // ======== Metadata =========
    string private baseTokenURI;

    // ======== Provenance =========
    string public provenanceHash = "";

    mapping(uint256 => string) private _tokenURIs;

    constructor () ERC721("NonFungibleHeroesLegendaryCollection", "NFHLC") {   
    }   

    // ======== Minting =========
    /**
    * @notice Mint specified amount of tokens
    * 
    * @param amount of tokens to mint
    * 
    * @param ipfsHashes ipfs hash of each token
    */
    function mint(uint amount, string[] memory ipfsHashes) public onlyOwner {
        require(totalSupply() + amount <= MAX_TOKENS, "Maximum number of tokens minted");
        require(amount == ipfsHashes.length, "Each token requires an IPFS hash");

        for(uint i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply() + 1;
            
            _mint(msg.sender, tokenId);
            _setTokenURI(tokenId, ipfsHashes[i]);
        }
    } 

    // ======== Metadata =========
    /**
    * @notice Update ipfs hash a specific token id
    * 
    * @param indexes array of all token ids to be updated
    * @param ipfsHashes array of all new hashes
    */
    function updateIpfs(uint[] memory indexes, string[] memory ipfsHashes) external onlyOwner {
        require(indexes.length == ipfsHashes.length, "Each token requires an IPFS hash");

        for(uint i = 0; i < indexes.length; i++) {
            _setTokenURI(indexes[i], ipfsHashes[i]);
        }
    }      

    /**
    * @notice Update base URI
    * 
    * @param _baseTokenURI the new base URI
    */
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;    
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "URI set for nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }       

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }  

    // ======== Provenance =========
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
    }
}