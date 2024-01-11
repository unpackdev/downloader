// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract OnionsTown is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1555;
    uint256 public constant MAX_PER_TX = 20;
    uint256 public constant MaxFreePerWallet = 5;
    uint256 public TOTAL_FREE = 999;
    uint256 public price = .001 ether;

    string private  baseTokenUri;

    bool public publicSale;
    bool public teamMinted;


    constructor() ERC721A("Onionstown.wtf", "OTW"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }


    function mint(uint256 amount) external payable {
        address _caller = _msgSender();
        require(!publicSale, "Paused");
        require(MAX_SUPPLY >= totalSupply() + amount, "Exceeds max supply");
        require(amount > 0, "No 0 mints");
        require(tx.origin == _caller, "No contracts");
        require(MAX_PER_TX >= amount , "Excess max per paid tx");
        
      if(TOTAL_FREE >= totalSupply()){
            require(MaxFreePerWallet >= amount , "Excess max per free tx");
        }else{
            require(MAX_PER_TX >= amount , "Excess max per paid tx");
            require(amount * price == msg.value, "Invalid funds provided");
        }


        _safeMint(_caller, amount);
    }

    function teamMint() external onlyOwner{
        require(!teamMinted,"Team already minted" );
        teamMinted = true;
        _safeMint(msg.sender, 349);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;
        
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }
    
    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }
    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function withdraw() external onlyOwner{
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
         require(os);
    }
}