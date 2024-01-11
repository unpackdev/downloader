// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155.sol";

contract ERC1155Contract is ERC1155, Ownable, PaymentSplitter, ReentrancyGuard {

    using Strings for uint256;

    struct Token {
        uint16 maxSupply;
        uint16 maxPerWallet;
        uint16 maxPerTransaction;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        bool preSaleIsActive;
        bool saleIsActive;
        bool claimIsActive;
        bool supplyLock;
        uint16 totalSupply;
    }

    mapping(uint256 => bytes32) public merkleRoots;
    mapping(uint256 => address) public burnerContracts;
    mapping(uint256 => Token) public tokens;
    mapping (uint256 => mapping(address => bool)) public fiatAllowlist;
    mapping (uint256 => mapping(address => uint16)) public hasMinted;
    mapping (uint256 => mapping(address => uint16)) public hasClaimed;
    string public name;
    string public symbol;
    string private baseURI;

    modifier onlyFiatMinter(uint256 _id) {
        require(fiatAllowlist[_id][msg.sender], "Not authorized");
        _;
    }

    modifier onlyBurner(uint256 _id) {
        require(msg.sender == burnerContracts[_id], "Not authorized");
        _;
    }

    constructor(
        uint16 _id,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner,
        Token memory _type
    ) ERC1155(_uri) PaymentSplitter(_payees, _shares) {
        name = _name;
        symbol = _symbol;
        baseURI = _uri;
        tokens[_id]= _type;
        transferOwnership(_owner);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _id.toString()))
                : baseURI;
    }

    function getClaimIneligibilityReason(address _address, uint16 _quantity, uint256 _id) public view returns (string memory) {
        if (tokens[_id].totalSupply + _quantity > tokens[_id].maxSupply) return "NOT_ENOUGH_SUPPLY";
        if (tokens[_id].preSaleIsActive || !tokens[_id].saleIsActive) return "NOT_LIVE";
        if (!tokens[_id].preSaleIsActive && tokens[_id].saleIsActive) return "";
    }

    function unclaimedSupply(uint256 _id) public view returns (uint256) {
        return tokens[_id].maxSupply - tokens[_id].totalSupply;
    }

    function price(uint256 _id) public view returns (uint256) {
        return tokens[_id].preSaleIsActive ? tokens[_id].preSalePrice : tokens[_id].pubSalePrice;
    }

    function addFiatMinter(uint256 _id, address _address) public onlyOwner {
        fiatAllowlist[_id][_address] = true;
    }

    function removeFiatMinter(uint256 _id, address _address) public onlyOwner {
        delete fiatAllowlist[_id][_address];
    }

    function setBurnerAddress(uint256 _id, address _address) external onlyOwner {
        burnerContracts[_id] = _address;
    }

    function burnForAddress(uint256 _id, uint256 _quantity, address _address) external onlyBurner(_id) {
        _burn(_address, _id, _quantity);
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
    function lockSupply(uint256 _id) public onlyOwner {
        tokens[_id].supplyLock = true;
    }

    function setRoot(uint256 _id, bytes32 _root) public onlyOwner {
        merkleRoots[_id] = _root;
    }

    function updateSaleState(
        uint256 _id, 
        bool _preSaleIsActive, 
        bool _saleIsActive, 
        bool _claimIsActive
    ) public onlyOwner {
        if (_preSaleIsActive) require(merkleRoots[_id] != "", "Root undefined");
        tokens[_id].preSaleIsActive = _preSaleIsActive;
        tokens[_id].saleIsActive = _saleIsActive;
        tokens[_id].claimIsActive = _claimIsActive;
    }

    function updateType(
        uint256 _id,
        uint16 _maxSupply,
        uint16 _maxPerWallet,
        uint16 _maxPerTransaction,
        uint72 _preSalePrice,
        uint72 _pubSalePrice
    ) public onlyOwner {
        require(tokens[_id].maxSupply >= tokens[_id].totalSupply, "Invalid supply");
        require(tokens[_id].maxSupply != 0, "Token exists");
        tokens[_id].maxSupply = _maxSupply;
        tokens[_id].maxPerWallet = _maxPerWallet;
        tokens[_id].maxPerTransaction = _maxPerTransaction;
        tokens[_id].preSalePrice = _preSalePrice;
        tokens[_id].pubSalePrice = _pubSalePrice;
    }

    function createType(
        uint256 _id,
        uint16 _maxSupply,
        uint16 _maxPerWallet,
        uint16 _maxPerTransaction,
        uint72 _preSalePrice,
        uint72 _pubSalePrice
    ) public onlyOwner {
        require(tokens[_id].maxSupply == 0, "Token exists");
        tokens[_id].maxSupply = _maxSupply;
        tokens[_id].maxPerWallet = _maxPerWallet;
        tokens[_id].maxPerTransaction = _maxPerTransaction;
        tokens[_id].preSalePrice = _preSalePrice;
        tokens[_id].pubSalePrice = _pubSalePrice;
    }

    function mint(
        uint256 _id,
        uint16 _quantity,
        bytes32[] memory _proof
    ) public payable nonReentrant {
        uint16 _maxPerWallet = tokens[_id].maxPerWallet;
        uint16 _currentSupply = tokens[_id].totalSupply;
        require(price(_id) * _quantity <= msg.value, "ETH incorrect");
        require(_currentSupply + _quantity <= tokens[_id].maxSupply, "Insufficient supply");
        require(tokens[_id].saleIsActive, "Sale inactive");
        if(tokens[_id].preSaleIsActive) {
            uint16 mintedAmount = hasMinted[_id][msg.sender] + _quantity;
            require(mintedAmount <= _maxPerWallet, "Invalid quantity");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_proof, merkleRoots[_id], leaf), "Not whitelisted");
            hasMinted[_id][msg.sender] = mintedAmount;
        } else {
            require(_quantity <= tokens[_id].maxPerTransaction, "Invalid quantity");
        }   
        tokens[_id].totalSupply = _currentSupply + _quantity;
        _mint(msg.sender, _id, _quantity, "");
    }

    function claimTo(address _address, uint16 _quantity, uint256 _id) public payable nonReentrant onlyFiatMinter(_id) {
        require(tokens[_id].saleIsActive, "Sale inactive");
        require(tokens[_id].totalSupply + _quantity <= tokens[_id].maxSupply, "Insufficient supply");
        require(price(_id) * _quantity <= msg.value, "ETH incorrect");
        _mint(msg.sender, _id, _quantity, "");
    }

    function claimFree(uint256 _id, uint16 _maxMint, uint16 _quantity, bytes32[] memory _proof) public {
        require(tokens[_id].claimIsActive, "Claim inactive");
        uint16 _hasClaimed = hasClaimed[_id][msg.sender];
        uint16 _currentSupply = tokens[_id].totalSupply;
        require(_currentSupply + _quantity <= tokens[_id].maxSupply, "Insufficient supply");
        bytes32 leaf = keccak256(abi.encode(msg.sender, _maxMint));
        require(MerkleProof.verify(_proof, merkleRoots[_id], leaf), "Not whitelisted");
        uint16 _claimable = _maxMint - _hasClaimed;
        require(_quantity <= _claimable, "Invalid quantity");
        tokens[_id].totalSupply = _currentSupply + _quantity;
        hasClaimed[_id][msg.sender] = _hasClaimed + _quantity;
        _mint(msg.sender, _id, _quantity, "");
    }

    function reserve(uint256 _id, address _address, uint16 _quantity) public onlyOwner nonReentrant {
        uint16 _currentSupply = tokens[_id].totalSupply;
        require(_currentSupply + _quantity <= tokens[_id].maxSupply, "Insufficient supply");
        tokens[_id].totalSupply = _currentSupply + _quantity;
        _mint(_address, _id, _quantity, "");
    }
}