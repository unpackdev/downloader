// SPDX-License-Identifier: MIT
// Developed by MatrixGlitch

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
                                                                                                                      
contract TheSteamVerse is ERC721A, Ownable
{
    using Strings for string;

    uint16 public freeMintLimitPerWallet = 1;
    uint16 public reservedTokensMinted = 0;
    uint16 public NUMBER_RESERVED_TOKENS = 200;
    uint16 public MAX_SUPPLY = 5888;
    uint256 public PRICE = 70000000000000000;
    uint256 public GOLDLISTPRICE = 50000000000000000;
    
    bool public revealed = false;
    bool public publicSaleIsActive = false;
    bool public goldlistIsActive = false;
    bool public whitelistIsActive = false;
    bool public freemintIsActive = false;

    string private _baseTokenURI;
    string public notRevealedUri;
    bytes32 rootGoldlist;
    bytes32 rootWhitelist;
    bytes32 rootFreemint;
    mapping(address => uint16) public addressGoldlistMintedBalance;
    mapping(address => uint16) public addressWhitelistBalance;
    mapping(address => uint16) public addressPublicSaleBalance;
    mapping(address => uint16) public addressFreemintBalance;

    constructor() ERC721A("The SteamVerse", "TSV") {}

    function goldlistMint(uint16 amount, bytes32[] memory proof) external payable
    {
        require(goldlistIsActive, "Goldlist sale is not active");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, rootGoldlist, leaf), "Address not allowed at this time");
        require(addressGoldlistMintedBalance[msg.sender] + amount <= 3, "Quantity exceeds goldlist allowance");
        require(msg.value >= GOLDLISTPRICE * amount, "Not enough ETH for this transaction");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressGoldlistMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function whitelistMint(uint16 amount, bytes32[] memory proof) external payable
    {
        require(whitelistIsActive, "Whitelist sale is not active");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, rootWhitelist, leaf), "Address not allowed at this time");
        require(addressWhitelistBalance[msg.sender] + amount <= 10, "Quantity exceeds whitelist allowance");
        require(totalSupply() + amount <= MAX_SUPPLY - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for this transaction");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressWhitelistBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function publicSaleMint(uint16 amount) external payable
    {
        require(publicSaleIsActive, "Public sale is not active");
        require(totalSupply() + amount <= MAX_SUPPLY - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for this transaction");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressPublicSaleBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function freeMint(uint16 amount, bytes32[] memory proof) external
    {
        require(freemintIsActive, "Free mint is not active");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, rootFreemint, leaf), "Address not allowed");
        require(addressFreemintBalance[msg.sender] + amount <= freeMintLimitPerWallet, "You have already claimed your free NFT");
        require(totalSupply() + amount <= MAX_SUPPLY - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressFreemintBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function mintReservedTokens(address to, uint16 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        reservedTokensMinted += amount;

        _safeMint(to, amount); 
    }

    function setPrice(uint256 newPrice) external onlyOwner 
    {
        PRICE = newPrice;
    }

    function setGoldlistPrice(uint256 newPrice) external onlyOwner 
    {
        GOLDLISTPRICE = newPrice;
    }

    function setQtyReservedTokens(uint16 newQty) external onlyOwner 
    {
        NUMBER_RESERVED_TOKENS = newQty;
    }

    function setMaxSupply(uint16 newSupplyQty) external onlyOwner 
    {
        MAX_SUPPLY = newSupplyQty;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function flipReveal() public onlyOwner {
        revealed = !revealed;
    }

    function flipGoldlistState() external onlyOwner
    {
        goldlistIsActive = !goldlistIsActive;
    }

    function flipWhitelistMintState() external onlyOwner
    {
        whitelistIsActive = !whitelistIsActive;
    }

    function flipPublicSaleState() external onlyOwner
    {
        publicSaleIsActive = !publicSaleIsActive;
    }

    function flipFreeMintState() external onlyOwner
    {
        freemintIsActive = !freemintIsActive;
    }

    function setRootGoldlist(bytes32 _root) external onlyOwner
    {
        rootGoldlist = _root;
    }

    function setRootWhitelist(bytes32 _root) external onlyOwner
    {
        rootWhitelist = _root;
    }
    
    function setRootFreeMint(bytes32 _root) external onlyOwner
    {
        rootFreemint = _root;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
  
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false) 
        {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }

    function withdraw() external onlyOwner
    {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}