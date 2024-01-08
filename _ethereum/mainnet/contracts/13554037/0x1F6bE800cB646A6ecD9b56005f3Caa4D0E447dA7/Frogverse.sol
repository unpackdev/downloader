// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Frogverse is ERC721, Ownable {
    using SafeMath for uint256;
    
    uint256 public constant MAX_FROGZ = 10000;

    uint256 public price;
    bool public hasSaleStarted = false;
    string baseContractURI;
    
    event Minted(uint256 tokenId, address owner);
    
    constructor(string memory baseURI, string memory baseContract) ERC721("Frogverse","FROGZ") {
        setBaseURI(baseURI);
        baseContractURI = baseContract;
        price = 0.05 ether;
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }
    
    function MintFrogz(uint256 quantity) public payable {
        mintFrogz(quantity, msg.sender);
    }
    
    function mintFrogz(uint256 quantity, address receiver) public payable {
        require(hasSaleStarted || msg.sender == owner(), "sale hasn't started");
        require(quantity > 0, "quantity cannot be zero");
        require(quantity <= 40, "exceeds 40");
        require(totalSupply().add(quantity) <= MAX_FROGZ || msg.sender == owner(), "sold out");
        require(msg.value >= price.mul(quantity) || msg.sender == owner(), "ether value sent is below the price");
                
        for (uint i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(receiver, mintIndex);
            emit Minted(mintIndex, receiver);
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }
    
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function withdrawAll(address walletFrogz) public onlyOwner {
        require(payable(walletFrogz).send(address(this).balance));
    }
}