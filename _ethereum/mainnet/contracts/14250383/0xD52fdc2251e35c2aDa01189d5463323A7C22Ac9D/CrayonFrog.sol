// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

 contract CrayonFrog is ERC721A, Ownable {
    using Address for address;
    using Strings for uint256;
    
    string public baseURI;

    uint256 public constant MAX_FROG = 5555;
    uint256 public constant TOTAL_FREE = 200;
    uint256 public constant MAX_FREE = 3;
    uint256 public constant MAX_PUBLIC = 20;

    string public constant BASE_EXTENSION = ".json";

    uint256 public constant PRICE = 0.008 ether;

    bool public saleActive = false;
    bool public adminClaimed = false;

    constructor() ERC721A("Crayon Frogs", "CFRG", MAX_PUBLIC) { 
    }
    
    function adminMint() public onlyOwner {
        require(!adminClaimed,                                                  "Admim has claimed");
        adminClaimed = true;
        _safeMint( msg.sender, 1); 
    }

    function freeMint(uint256 _numberOfMints) private {
        require(_numberOfMints > 0 && _numberOfMints <= MAX_FREE,              "Invalid mint amount");
        if(totalSupply() + _numberOfMints > TOTAL_FREE){
            _safeMint( msg.sender, TOTAL_FREE - totalSupply()); 
        } else {
            _safeMint( msg.sender, _numberOfMints); 
        }   
    }
    
    function publicMint(uint256 _numberOfMints) private {
        require(_numberOfMints > 0 && _numberOfMints <= MAX_PUBLIC,             "Invalid purchase amount");
        require(totalSupply() + _numberOfMints <= MAX_FROG,                     "Purchase would exceed max supply of tokens");
        require(PRICE * _numberOfMints == msg.value,                            "Ether value sent is not correct");
        
        _safeMint( msg.sender, _numberOfMints );
    }

    function mint(uint256 _numberOfMints) public payable {
        require(saleActive,                                                     "Not started");
        require(tx.origin == msg.sender,                                        "What ya doing?");
        if(totalSupply() < TOTAL_FREE){
            freeMint(_numberOfMints);
        } else {
            publicMint(_numberOfMints);
        }
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
         require(
            _exists(_id),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _id.toString(), BASE_EXTENSION))
            : "";
    }

    function withdraw(address _address) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_address).transfer(balance);
    }    
}