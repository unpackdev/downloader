// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./console.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract MutantYeti is ERC721A, Ownable {
    using Strings for uint256;

    bool private _isSaleActive = false; 
    bool private _revealed = false; 

    // Constants
    uint256 public constant MAX_SUPPLY = 10000; 
    uint256 public mintPrice = 0.02 ether ;
    uint256 public maxBalance = 1000; 
    uint256 public maxMint = 1000; 

    string baseURI;
    string public notRevealedUri;
    string private baseExtension = ".json";

    mapping(uint256 => string) private _tokenURIs;
   

    
    constructor()        
    {
       setNotRevealedURI('https://opensea.mypinata.cloud/ipfs/QmaLeZHJvPFWyrzw5HXACLTyJAqu2KmTdGh46rDwdTE6ic');
        
    }


   
    function mint(uint256 tokenQuantity) public payable {
        if(msg.sender != owner()){
            require(
                totalSupply() + tokenQuantity <= MAX_SUPPLY,
                "Sale would exceed max supply"
            );
            require(_isSaleActive, "Sale must be active to mint XboxFans");
            require(
                balanceOf(msg.sender) + tokenQuantity <= maxBalance,
                "Sale would exceed max balance"
            );
            
            require(
                tokenQuantity * mintPrice <= msg.value,
                "Not enough token sent"
            );
            require(tokenQuantity <= maxMint, "Can only mint 5 tokens at a time");
        }
        
        if (totalSupply()+tokenQuantity < MAX_SUPPLY) {
            _safeMint(msg.sender, tokenQuantity);
        }
       
      

    }

    

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

        if (_revealed == false) {
            
            console.log('notReveale',notRevealedUri);
            return notRevealedUri;
        }

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

       
        if (bytes(_tokenURI).length > 0) {
            console.log('base',string(abi.encodePacked(base, _tokenURI)));
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        
        console.log('open',string(abi.encodePacked(base, tokenId.toString(), baseExtension)));
        return string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    
    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }

    
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

   
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    
    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    
    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    
    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
   
  
}
