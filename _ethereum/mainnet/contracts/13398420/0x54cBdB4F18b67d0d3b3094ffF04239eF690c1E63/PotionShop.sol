// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract PotionShop is ERC721Enumerable, Ownable {  
    using Address for address;
    using Strings for uint256;
    
    // Starting and stopping sale and presale
    bool public saleActive = false;
    bool public presaleActive = false;
    
    //revealing the Metadata
    bool public revealed = false;


    // Price of each token
    uint256 public price = 0.069 ether;

    // Maximum limit of tokens that can ever exist
    uint256 constant MAX_SUPPLY = 1000;

    // The base link that leads to the image / video of the token
    string public baseTokenURI;
    string public notRevealedUri;

    string public baseExtension = ".json";

    // Team addresses for withdrawals
    address public a1;

    // List of addresses that have a number of reserved tokens for presale
    mapping (address => uint256) public presaleReserved;

    constructor (string memory newBaseURI, string memory _initNotRevealedUri) ERC721 ("The Potion Shop", "TPS") {
        setBaseURI(newBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // See which address owns which tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    // Exclusive presale minting
    function mintPresale(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        uint256 reservedAmt = presaleReserved[msg.sender];
        require( presaleActive,                  "Presale isn't active" );
        require( reservedAmt > 0,                "No tokens reserved for your address" );
        require( _amount <= reservedAmt,         "Can't mint more than reserved" );
        require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
        require( msg.value == price * _amount,   "Wrong amount of ETH sent" );
        presaleReserved[msg.sender] = reservedAmt - _amount;
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    // Standard mint function
    function mintToken(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        require( saleActive,                     "Sale isn't active" );
        require( _amount > 0 && _amount < 21,    "Can only mint between 1 and 20 tokens at once" );
        require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
        require( msg.value == price * _amount,   "Wrong amount of ETH sent" );
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    
    // Edit reserved presale spots
    function editPresaleReserved(address[] memory _a) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            presaleReserved[_a[i]] = 5; // Only 5 reserved per account
        }
    }
    
    // override to ensure correct tokenURI
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
      {
        require(
          _exists(tokenId),
          "ERC721Metadata: URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }
    
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
      }


    // Start and stop presale
    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    // Start and stop sale
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    
    function reveal() public onlyOwner() {
      revealed = true;
    }

    // Set a different price in case ETH changes drastically
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // Set team address
    function setAddress(address _a) public onlyOwner {
        a1 = _a;
    }

    // Withdraw funds from contract for the team
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(a1).call{value: address(this).balance}("");
        require(success);
    }
}
