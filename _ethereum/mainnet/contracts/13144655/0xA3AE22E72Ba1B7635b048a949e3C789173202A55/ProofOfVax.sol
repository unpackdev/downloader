// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract ProofOfVax is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public price = 20000000000000000; // 0.02 ETH (in Wei)
    mapping (uint256 => string) private _tokenURIs;
    Counters.Counter private _tokenIdCounter;


    constructor() ERC721("Proof of Vax", "PROOFOFVAX") {}


    /**
     * @param to address to mint to
     * @param _IPFSHash of COVID Vaccination card.
     */
    function Mint(address to, string memory _IPFSHash) public payable {
         require(msg.value >= price, "ERROR: Not enough Ether sent. The price to mint is 0.02 ETH.");

        _tokenIdCounter.increment();
        _safeMint(to, _tokenIdCounter.current());
        _setTokenHash(_tokenIdCounter.current(), _IPFSHash);
    }


    /**
     * @notice Set tokenURI for a specific tokenId
     * @param tokenId of an NFT
     * @param _tokenHash to set for the given tokenId (IPFS hash)
     */
    function _setTokenHash(uint256 tokenId, string memory _tokenHash) internal {
        require(_exists(tokenId), "ERROR: Hash set of nonexistent token");
        _tokenURIs[tokenId] = _tokenHash;
    }


    /**
     * @notice return the Metadata for this NFT
     * @param tokenId to check if token exists
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked('data:application/json;utf8,{"name":"Proof Of Vax ', tokenId.toString(), '/', _tokenIdCounter.current().toString(), '", "description":"My COVID Vaccination Card",','"image":"ipfs://', _tokenURIs[tokenId], '"}'));

    }

    /**
     * @notice withdraw contract funds 
     */
    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }


}