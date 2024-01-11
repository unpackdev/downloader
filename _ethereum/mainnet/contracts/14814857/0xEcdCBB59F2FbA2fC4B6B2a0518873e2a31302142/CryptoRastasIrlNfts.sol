// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract CryptoRastasIrlNfts is ERC721, Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    
    uint256 public price;
    bool public hasSaleStarted = false;
    string baseContractURI;
    
    event Minted(uint256 tokenId, address owner);
    
    constructor(string memory baseURI, string memory baseContract) ERC721("CryptoRastas IRL NFTS","RastaIRL") {
        setBaseURI(baseURI);
        baseContractURI = baseContract;
        price = 0.06 ether;
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }
    
    function MintRasta(uint256 quantity, bytes32 data, bytes memory signature, address account) public payable {
        mintRasta(quantity, msg.sender, data, signature, account);
    }
    
    function mintRasta(uint256 quantity, address receiver, bytes32 data, bytes memory signature, address account) public payable {
        require(verify(data, signature) == account, "Not authorized");
        require(hasSaleStarted || msg.sender == owner(), "Sale hasn't started");
        require(quantity > 0, "Quantity cannot be zero");
        require(quantity <= 3, "Exceeds 3");
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

    function withdrawAll(address wallet) public onlyOwner {
        require(payable(wallet).send(address(this).balance));
    }

    function verify(bytes32 hash, bytes memory signature) internal pure returns (address) {
       return ECDSA.recover(hash, signature);
    }
}