// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Burnable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract ArtistsForUkraine is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
 
    // Base Url
    string public baseUri = "https://ipfs.io/ipfs/QmXkasMg44Pr8BKSWWQEGr9itRfwKjMgh7XgBMMgGcCXfJ/";

    uint256 public constant MINT_PRICE = 50000000000000000; // 0.05 ETH.
    uint256 public constant MAX_TOKENS = 5000;
    
    // SLAVA UKRAINI !!! 
    address public constant BENEFICIARY_ADDRESS = 0x165CD37b4C644C2921454429E7F9358d18A45e14;
            

    constructor() ERC721("ArtistsForUkraine", "AFU") {}

    function exists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }
    
    /**
    *   Public function for minting.
    */
    function mintNFT(uint256 numberOfTokens) public payable {
        
        uint256 totalIssued = _tokenIds.current();

        require(numberOfTokens != 0, "Mint at least 1 token");
        require(totalIssued.add(numberOfTokens) <= MAX_TOKENS, "Minting would exceed max. supply");
        require(MINT_PRICE.mul(numberOfTokens) <= msg.value, "Not enough Ether sent.");
        
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }
    }

    /*
    *   setBaseUri setter
    */
    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    /*
    *   Withdraw Fiunds to beneficiary
    */
    function withdraw() public payable {
         (bool success,) = payable(BENEFICIARY_ADDRESS).call{value: address(this).balance}("");
         require(success, "ERROR");
    }

    /*
    *   Overrides
    */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    receive () external payable virtual {}
}