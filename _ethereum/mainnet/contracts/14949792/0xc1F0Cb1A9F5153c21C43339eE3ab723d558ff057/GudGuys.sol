// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract GudGuys is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public constant MAX_MINT_FREE = 1;
    uint256 public constant MAX_MINT_PAID = 10;
    uint256 public constant PRICE = .002 ether;
    
    string private _baseTokenURI = "ipfs://QmY8wauKdmd1aSnyp5kSg6fRotT5zGmCHJepSivNTsbdrm/";
    string public _notRevealedTokenURI = "";

    bool public isRevealed = true;
    bool public isActive = true;
    bool public isFree = true;

    mapping(address => uint256) public totalMint;
    mapping(address => bool) public secs;

    bytes32 public wLMerkleRoot = 0x210d641bfc0adc82781fb8130eb5f8ed9a520cee1f5dcbe36bfd727d0ed4599d;

    constructor () ERC721A("GudGuys", "GUYS") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        _baseTokenURI = _URI;
    }

    function setNotRevealedURI(string memory _URI) external onlyOwner {
        _notRevealedTokenURI = _URI;
    }

    function setRevealed(bool _state) external onlyOwner {
        isRevealed = _state;
    }

    function setActive(bool _state) external onlyOwner {
        isActive = _state;
    }

    function setFree(bool _state) external onlyOwner {
        isFree = _state;
    }


    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        wLMerkleRoot = _merkleRoot;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require( _exists(_tokenId),"no token");

        if (isRevealed == false) {
            return _notRevealedTokenURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : "";
    }
    


    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function freeMint(bytes32[] memory _merkleProof, address sec, uint256 _quantity) external payable nonReentrant callerIsUser{
        require(isActive, "Mint must be active");
        require(isFree, "Freemint must be active");
        require(_quantity > 0, "Cannot mint none");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "No enough NFTs left");
        require((totalMint[msg.sender] + _quantity)  <= MAX_MINT_FREE, "Cannot mint free more than 1");
        require(MerkleProof.verify(_merkleProof, wLMerkleRoot, keccak256(abi.encodePacked(sec))), "Invalid proof");
        require(secs[sec] == false, "stop secs");
        totalMint[msg.sender] += _quantity;
        secs[sec] = true;
        _safeMint(msg.sender, _quantity);
    }

    function mint(uint256 _quantity) external payable nonReentrant callerIsUser{
        require(isActive, "Mint must be active");
        require(_quantity > 0, "Cannot mint none");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Cannot mint beyond max supply");
        require((totalMint[msg.sender] +_quantity) <= MAX_MINT_PAID, "Cannot mint more than 10 with same wallet");
        require(msg.value >= (PRICE * _quantity), "No enough money");

        totalMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(uint256 _quantity) external nonReentrant onlyOwner{
        require(isActive, "Contract must be active");
        _safeMint(msg.sender, _quantity);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        //---
    }
}