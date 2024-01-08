// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract NotFromTheZoo is ERC721, Ownable {
    using SafeMath for uint256;
    
    uint256 public constant MAX = 8888;

    uint256 public price;
    bool public hasSaleStarted = false;
    string baseContractURI;
    
    event Minted(uint256 tokenId, address owner);
    
    constructor(string memory baseURI, string memory baseContract) ERC721("Not From The Zoo","NFTZ") {
        setBaseURI(baseURI);
        baseContractURI = baseContract;
        price = 0.04 ether;
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }
    
    function MintNFTZ(uint256 quantity) public payable {
        mintNFTZ(quantity, msg.sender);
    }
    
    function mintNFTZ(uint256 quantity, address receiver) public payable {
        require(hasSaleStarted || msg.sender == owner(), "sale hasn't started");
        require(quantity > 0, "quantity cannot be zero");
        require(quantity <= 40, "exceeds 40");
        require(totalSupply().add(quantity) <= MAX || msg.sender == owner(), "sold out");
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

    function withdrawAll(address walletDonation, address walletNFTZ) public onlyOwner {
        uint amount = address(this).balance;

        require(payable(walletDonation).send(amount.mul(60).div(100)));
        require(payable(walletNFTZ).send(amount.mul(40).div(100)));
    }
}