// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract INTROVERSE is ERC721A,Ownable,ReentrancyGuard {
    using Strings for uint256;

    uint256 public maxSupply = 1555;
    uint256 public price = 0.09999 ether;
    uint256 public regularMintMax = 3;

    string public _baseTokenURI;
    string public _baseTokenEXT;
    string public notRevealedUri = "ipfs://Qmd8VksrkacbZzJiqH39zdXqHZh35YZxcnDLzBuyDCctZT/";

    bool public revealed = false;
    bool public paused = true;
    bool public whitelistSale = true;

    uint256 public reserved = 582;
    uint256 public airDropCount = 0;
    uint256 public whitelistMaxMint = 2;
    uint256 public whitelistPrice = 0.08888 ether;
    bytes32 public merkleRoot = 0x8545ca6348e4ebc8c95dc82ca66ffd65b4eb21232ac420aa1a4d08b9284033ce;

    struct MintTracker{
        uint256 _regular;
        uint256 _whitelist;
    }

    mapping(address => MintTracker) public _totalMinted;

    constructor() ERC721A("INTROVERSE","INT") {}

    function mint(uint256 _mintAmount) public payable nonReentrant {
        require(tx.origin == msg.sender,"Contract Calls Not Allowed");
        require(!paused,"Contract Minting Paused");
        require(!whitelistSale,": Cannot Mint During Whitelist Sale");
        require(msg.value >= price * _mintAmount,"Insufficient FUnd");
        require(_mintAmount+_totalMinted[msg.sender]._regular <= regularMintMax,"You cant mint more,Decrease MintAmount or Wait For Opensea" );
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply - reserved,": No more NFTs to mint,decrease the quantity or check out OpenSea.");
        _safeMint(msg.sender,_mintAmount);
        _totalMinted[msg.sender]._regular+=_mintAmount;
    }

    function WhiteListMint(uint256 _mintAmount,bytes32[] calldata _merkleProof) public payable nonReentrant{
        require(tx.origin == msg.sender,"Contract Calls Not Allowed");
        require(!paused,"Contract Minting Paused");
        require(whitelistSale,": Whitelist is paused.");
        require(_mintAmount+_totalMinted[msg.sender]._whitelist <= whitelistMaxMint,"You cant mint more,Decrease MintAmount or Wait For Public Mint" );
        require(msg.value >= whitelistPrice * _mintAmount,"Insufficient FUnd");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof,merkleRoot,leaf),"You are Not whitelisted");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply -reserved,": No more NFTs to mint,decrease the quantity or check out OpenSea.");
        _safeMint(msg.sender,_mintAmount);
        _totalMinted[msg.sender]._whitelist+=_mintAmount;
    }

    
    function _airdrop(uint256 amount,address[] memory _address) public onlyOwner {
        uint256 _mintAmount = _address.length * amount;
        require(airDropCount+_mintAmount <= reserved,"Airdrop Limit Drained!");
        for(uint256 i=0;i<_address.length;i++){
            _safeMint(_address[i], amount);
        }
        airDropCount+=_mintAmount;
        
    }

    function startPublicSale() public onlyOwner{
        paused = false;
        whitelistSale = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setPublicMintMax(uint256 newMax) public onlyOwner {
        regularMintMax = newMax;
    }

    function setWhiteListMax(uint256 newMax) public onlyOwner {
        whitelistMaxMint = newMax;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        if (revealed == false) {
            return notRevealedUri;
        } else {
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,tokenId.toString(),_baseTokenEXT)) : "";
        }
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function toogleWhiteList() public onlyOwner{
        whitelistSale = !whitelistSale;
    }

    function toogleReveal() public onlyOwner{
        revealed = !revealed;
    }

    function tooglePause() public onlyOwner{
        paused = !paused;
    }

    function changeURLParams(string memory _nURL,string memory _nBaseExt) public onlyOwner {
        _baseTokenURI = _nURL;
        _baseTokenEXT = _nBaseExt;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setWLPrice(uint256 newPrice) public onlyOwner {
        whitelistPrice = newPrice;
    }

    function setMerkleRoot(bytes32 merkleHash) public onlyOwner {
        merkleRoot = merkleHash;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success,"Transfer failed.");
    }

}