// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ECDSA.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract MetaVillage is ERC721Enumerable, Ownable, ReentrancyGuard {

    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 private _amountMinted = 0;

    uint256 public constant _maximumSupply = 9159;
    uint256 public constant _maximumMint = 10;

    uint256 _price = 0.1 ether;

    string public baseURI = "ipfs://bafybeigjnslupyz6shjnwp4xziebllfhubmemjef2f7llcrg25kcafmbv4/mvjs/";
    bytes32 public _merkleRoot = 0x9829102c6fc1fc0825be9e15567b88d0d5ab3f3facab47dd7e0e6d483fa01ed8;

    address private _owner;

    mapping(address => uint256) public _balances;
    mapping(address => uint256) public _giveaways;

    enum SaleStatus {
        NotAvailable,
        Presale,
        Sale,
        SoldOut
    }

    SaleStatus public _saleStatus = SaleStatus.Presale;

    event PresaleTokenMint(address indexed minter, uint256 amount, uint256 price);
    event TokenMint(address indexed minter, uint256 amount, uint256 price);

    constructor() ERC721( "MetaVillage", "MVIL" ) {
        transferOwnership(msg.sender);
    }

    function getMaxSupply() public pure returns (uint256) {
        return _maximumSupply;
    }

    function isWhitelisted(bytes32[] calldata _merkleProof) public view returns (bool) {

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, _merkleRoot, leaf);

    }

    function testMerkleTree(bytes32 _addr, bytes32[] calldata _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, _merkleRoot, _addr);
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }


    // SALE STATUS
    function SetPresaleStatus() public onlyOwner {
        _price = 0.1 ether;
        _saleStatus = SaleStatus.Presale;
    }

    function SetPublicSaleStatus() public onlyOwner {
        _price = 0.17 ether;
        _saleStatus = SaleStatus.Sale;
    }

    function DisableSale() public onlyOwner {
        _saleStatus = SaleStatus.NotAvailable;
    }

    // WHITELIST
    function setMerkleRoot(bytes32 mrklrt) public onlyOwner {
        _merkleRoot = mrklrt;
    }

    // URI
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    // MINT

    function presaleMint(bytes32[] calldata _merkleProof) external payable nonReentrant {

        uint256 price = 0.1 ether;

        require(_saleStatus == SaleStatus.Presale, "METAVILLAGE: PreSale is not available right now.");
        require((_balances[msg.sender] - _giveaways[msg.sender]) < 1, "METAVILLAGE: PreSale limit is one nft.");
        require(msg.value >= price, "METAVILLAGE: Price must be 0.1 ETH");

        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, _merkleRoot, _leaf), "METAVILLAGE: You have not been whitelisted!");

        _balances[msg.sender] += 1;
        _safeMint(msg.sender, _amountMinted + 1);

        _amountMinted += 1;

        emit PresaleTokenMint(msg.sender, 1, msg.value);

    }

    function publicSaleMint(uint256 amount) public payable nonReentrant {
        
        require(_saleStatus == SaleStatus.Sale, "METAVILLAGE: Public sale is not available right now.");
        require((_balances[msg.sender] - _giveaways[msg.sender]) + amount <= _maximumMint, "METAVILLAGE: Maximum 10 nfts per person.");
        require(_amountMinted < _maximumSupply, "METAVILLAGE: Maximum supply reached.");
        require(_amountMinted + amount <= _maximumSupply, "METAVILLAGE: Mint amount will exceed maximum supply.");
        require(msg.value >= _price * amount, "METAVILLAGE: Insuficient ETH");

        _balances[msg.sender] += amount;

        for( uint256 i = 1; i <= amount; i++ ) {
            _safeMint(msg.sender, _amountMinted + i);
        }

        emit TokenMint(msg.sender, amount, msg.value);

        _amountMinted += amount;


    }

    function giveAwayBatch( address[] calldata to, uint256[] calldata amount ) external onlyOwner {

        require(to.length == amount.length, "METAVILLAGE: Giveaway amounts mismatch.");

        uint256 _sumAmount = 0;
        for( uint256 i = 0; i < amount.length; i++ ){
            _sumAmount += amount[i];
        }
        require( _amountMinted + _sumAmount <= _maximumSupply, "METAVILLAGE: Mint will exceed maximum supply.");

        for( uint256 i = 0; i < to.length; i++ ){
            _balances[to[i]] += amount[i];
            _giveaways[to[i]] += amount[i];

            for( uint256 j = 1; j <= amount[i]; j++ ){
                _safeMint(to[i], _amountMinted + j);
            }

            emit TokenMint(to[i], amount[i], 0);
            _amountMinted += amount[i];
        }

    }


    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
                : "";
    }


    // WITHDRAWAL AND BALANCE

    function contract_balance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }
    
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


}