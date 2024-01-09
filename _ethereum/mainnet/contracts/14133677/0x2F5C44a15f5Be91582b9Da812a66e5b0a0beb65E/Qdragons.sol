// SPDX-License-Identifier: MIT

/**
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~  Qdragons  ~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
    
contract Qdragons is ERC721Enumerable, Ownable {
    
    // Set params
    string public PROVENANCE = "";
    uint256 public constant MAX_SUPPLY = 3333;
    
    uint256 public _price = 0.03 ether;
    uint256 public _maxMint = 10;
    string public _baseTokenURI;
    uint256 private _reserved = 30;
    bool public _saleActive = false;

    // Team addresses for withdrawals
    address a1 = 0x940b90a16c9b70F7BDc77d20F405bfB4Bd8D3d35; // Team 1
    address a2 = 0x0184D93d17C4AF3ACa98b5b4FC5a44a4e8B377D2; // Team 2
    address a3 = 0x96b50474bB0dC4e5288240A33648dE5f5fd955b3; // Team 3
    address a4 = 0x5ffbBEB3DEbd160B9E7ac04647c24f463c45F0B3; // Qmmunity Fund
    
    constructor(string memory baseURI) ERC721("Qdragons", "QD") {
        setBaseURI(baseURI);

        // Team gets the first tokens
        _safeMint( a1, 0);
        _safeMint( a2, 1);
        _safeMint( a3, 2);
    }

    // Return full base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    // Set base URI   
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Set collection provenance
    function setProvenance(string memory _provenance) public onlyOwner {
       PROVENANCE = _provenance;
    }
    
    // Mint standard
    function mint(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        require( _saleActive,                           "Sale not active" );
        require( _amount > 0 && _amount < (_maxMint+1), "Exceeds max mint" );
        require( supply + _amount <= MAX_SUPPLY,        "Exceeds max supply" );
        require( msg.value == _price * _amount,         "Ether sent incorrect" );
        
        for(uint256 i; i < _amount; i++){
          _safeMint( msg.sender, supply + i );
        }
    }

    // Mint reserved 
    function mintReserved(address _to, uint256 _amount) public onlyOwner {
        uint256 supply = totalSupply();
        require( _amount <= _reserved,           "Exceeds reserved amount" );
        require( supply + _amount <= MAX_SUPPLY, "Exceeds max supply" );
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }
        _reserved -= _amount;
    }

    // Utility function to get tokens of owner
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
       
    // Set price
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }
     
    // Set max mint
    function setMaxMint(uint256 _newMaxMint) public onlyOwner() {
        _maxMint = _newMaxMint;
    }
        
    // Set sale status
    function setSaleStatus(bool _newSaleStatus) public onlyOwner {
        _saleActive = _newSaleStatus;
    }
    
    // Withdraw from contract
    function withdrawAll() public payable onlyOwner {
        uint256 share = address(this).balance / 100;
        require(payable(a1).send(share * 30));
        require(payable(a2).send(share * 30));
        require(payable(a3).send(share * 30));
        require(payable(a4).send(share * 10));
    }
}
