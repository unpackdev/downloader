// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract CryptoRastasStories is ERC721, Ownable {
    using SafeMath for uint256;
    
    uint256 public constant MAX = 50;
    string baseContractURI;
    
    event Minted(uint256 tokenId, address owner);
    
    constructor(string memory baseURI, string memory baseContract) ERC721("Cryptorastas Stories","RASTA STORIES") {
        setBaseURI(baseURI);
        baseContractURI = baseContract;
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }
    
    function MintStories(uint256 quantity) public onlyOwner {
        mintStories(quantity, msg.sender);
    }
    
    function mintStories(uint256 quantity, address receiver) public onlyOwner {
        require(quantity > 0, "quantity cannot be zero");
        require(totalSupply().add(quantity) <= MAX, "sold out");
                
        for (uint i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(receiver, mintIndex);
            emit Minted(mintIndex, receiver);
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
}