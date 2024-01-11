// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Context.sol";
import "./Ownable.sol";

import "./ERC721A.sol";



pragma solidity ^0.8.7;


contract NakedEmperors is Ownable, ERC721A {
    
    uint256 public maxSupply                    = 7200;
    uint256 public maxFreeSupply                = 720;
    
    uint256 public maxPerAddressDuringMint      = 20;
    uint256 public maxPerAddressDuringFreeMint  = 1;
    
    uint256 public price                        = 0.005 ether;
    bool    public pause                        = true;

    bool    public isMetadataLocked             = false;
    string private _baseTokenURI;

    mapping(address => uint256) public mintedAmount;
    mapping(address => uint256) public freeMintedAmount;

    mapping(address => bool) public projectProxy;
    mapping(uint256 => uint256) private freeMintClaimBitMask;


    constructor() ERC721A("Naked Emperors", "NEMPS") {
       
    }

    modifier mintCompliance() {
        require(!pause, "Sale is not active yet.");
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        _;
    }

    function mint(uint256 _quantity) external payable mintCompliance() {
        require(
            msg.value >= price * _quantity,
            "Insufficient Fund."
        );
        require(
            maxSupply >= totalSupply() + _quantity,
            "Exceeds max supply."
        );
        uint256 _mintedAmount = mintedAmount[msg.sender];
        require(
            _mintedAmount + _quantity <= maxPerAddressDuringMint,
            "Exceeds max mints per address!"
        );

        mintedAmount[msg.sender] = _mintedAmount + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function freeMint(uint256 _quantity) external mintCompliance() {
        require(
            maxFreeSupply >= totalSupply() + _quantity,
            "Exceeds max free supply."
        );
        uint256 _freeMintedAmount = freeMintedAmount[msg.sender];
        require(
            _freeMintedAmount + _quantity <= maxPerAddressDuringFreeMint,
            "Exceeds max free mints per address!"
        );
        freeMintedAmount[msg.sender] = _freeMintedAmount + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function flipSale() public onlyOwner {
        pause = !pause;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),".json")) : '';
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        require(!isMetadataLocked, "metadata is finalized");
        _baseTokenURI = baseURI;
    }



    function burnSupply(uint256 _amount) public onlyOwner {
        maxSupply -= _amount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function lockMetadata() external onlyOwner {
        isMetadataLocked = true;
    }  
}
