// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract DONTWORRYERC721 is ERC721, Ownable {
    using Counters for Counters.Counter;

    
    Counters.Counter private _tokenIdCounter;
    string private ipfsHash;


    constructor() ERC721("3LAU - Dont Worry", "3LAUDONTWORRY") {}

    /**
    * @notice Mint a single nft
    */
    function safeMint(address to) public onlyOwner {
        _tokenIdCounter.increment();
        _safeMint(to, _tokenIdCounter.current());
    }

    /**
     * @notice Mint multiple NFTs
     * @param to address that new NFTs will belong to
     * @param amount of NFT Token Ids to mint
     * @param preApprove optional account that is pre-approved to move tokens after token creation.
     */
    function batchMint(address to, uint256 amount, address preApprove) external onlyOwner{
        for (uint i = 0; i < amount; i++){
            safeMint(to);

            if(preApprove != address(0)){
                _approve(preApprove, _tokenIdCounter.current());
            }

        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    /**
     * @notice change the IPFS hash for all NFTSs
     */
    function setIPFSHash(string calldata _ipfsHash) external onlyOwner{
        ipfsHash = _ipfsHash;
    }

    /**
     * @notice return the IPFS URI for the NFT
     * @param tokenId to check if token exists
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, ipfsHash))
            : '';
    }

    
}
