// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract CryptorastasRemixes is ERC721, Ownable {
    using SafeMath for uint256;
    
    uint256 public constant MAX_RASTA_RMX = 10000;
    string baseContractURI;
    
    event Minted(uint256 tokenId, address owner);
    
    constructor(string memory baseURI, string memory baseContract) ERC721("Cryptorastas Remixes","RASTA-RMX") {
        setBaseURI(baseURI);
        baseContractURI = baseContract;
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }
    
    function MintRastaRemix(uint256 quantity) public onlyOwner {
        mintRastaRemix(quantity, msg.sender);
    }
    
    function mintRastaRemix(uint256 quantity, address receiver) public onlyOwner {
        require(quantity > 0, "quantity cannot be zero");
        require(totalSupply().add(quantity) <= MAX_RASTA_RMX, "exceeds max supply");
                
        for (uint i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(receiver, mintIndex);
            emit Minted(mintIndex, receiver);
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
}