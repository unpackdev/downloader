// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Ownable.sol"; 
import "./ERC721A.sol"; 
import "./ReentrancyGuard.sol"; 
import "./MerkleProof.sol"; 
import "./Strings.sol"; 

contract FartBogglers is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256; 

    string public uriPrefix = ""; 
    string public uriSuffix = ".json"; 
    string public hiddenMetadataURI; 

    uint256 public maxSupply; 
    uint256 public maxMintAmountPerAddrWL;
    uint256 public maxMintAmountPerAddrPUB;  
    uint256 public price = 0.03 ether; 


    bytes32 public merkleRoot; 
    mapping(address => uint256) public whitelistedAmt; 
    mapping(address => uint256) public publicAmt; 

    bool public paused = false; 
    bool public revealed = false;
    bool public whiteListSale = false; 
    bool public publicSale = true;  


    constructor(
        uint256 _maxSupply,
        uint256 _maxMintAmountPerAddrWL,
        uint256 _maxMintAmountPerAddrPUB,
        string memory _hiddenMetadataUri
    ) ERC721A("Fart Bogglers", "BOGGLE") {
        maxSupply = _maxSupply;
        setMaxMintAmountPerAddrWL(_maxMintAmountPerAddrWL); 
        setMaxMintAmountPerAddrPUB(_maxMintAmountPerAddrPUB); 
        setHiddenMetadataURI(_hiddenMetadataUri); 
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(msg.value == price * _mintAmount, "Incorrect ETH"); 
        require(totalSupply() + _mintAmount <= maxSupply, "Sold out"); 
        _; 
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
            require(whiteListSale, "Whitelist sale is not current"); 
            bytes32 leaf = keccak256(abi.encodePacked(_msgSender())); 
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Proof"); 
            uint256 mintedCount = whitelistedAmt[msg.sender]; 
            require(mintedCount + _mintAmount <= maxMintAmountPerAddrWL, "Max minted"); 
            
            whitelistedAmt[msg.sender]+= _mintAmount; 

            _safeMint(_msgSender(), _mintAmount); 

    }

    function publicMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
        require(publicSale, "Mint is not live yet"); 
        require(_numberMinted(msg.sender) + _mintAmount <= maxMintAmountPerAddrPUB, "Exceeds your allocation."); 
        uint256 mintCountPublic = publicAmt[msg.sender];
        require(mintCountPublic + _mintAmount <= maxMintAmountPerAddrPUB, "Max minted"); 

        publicAmt[msg.sender]+= _mintAmount; 

        _safeMint(_msgSender(), _mintAmount); 
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1; 
    }
    
    // ----- Prevent minting from external Contract.
    modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function publicMint() public onlyOwner {
        publicSale = !publicSale;
    }

    function whitelistMint() public onlyOwner {
        whiteListSale = !whiteListSale; 
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price; 
    }

    function setMaxMintAmountPerAddrWL(uint256 _maxMintAmountPerAddrWL) public onlyOwner {
        maxMintAmountPerAddrWL = _maxMintAmountPerAddrWL; 
    }

    function setMaxMintAmountPerAddrPUB(uint256 _maxMintAmountPerAddrPUB) public onlyOwner {
        maxMintAmountPerAddrPUB = _maxMintAmountPerAddrPUB;
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(totalSupply() <= _mintAmount, "Sold Out"); 
        _safeMint(_receiver, _mintAmount); 
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state; 
    }

    function setHiddenMetadataURI(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataURI = _hiddenMetadataUri; 
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix; 
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix; 
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os, "Withdraw failed!");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}