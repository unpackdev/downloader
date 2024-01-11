// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155.sol";

contract ERC1155Contract is ERC1155, Ownable, PaymentSplitter, ReentrancyGuard {

    using Strings for uint256;

    struct InitialParameters {
        uint256 launchpassId;
        string name;
        string symbol;
        string uri;
        uint256 id;
        uint24 maxSupply;
        uint24 maxPerWallet;
        uint24 maxPerTransaction;
        uint72 preSalePrice;
        uint72 pubSalePrice;
    }

    struct TokenType {
        uint24 maxSupply;
        uint24 maxPerWallet;
        uint24 maxPerTransaction;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        bool preSaleIsActive;
        bool saleIsActive;
        bool supplyLock;
        address creator;
        uint256 totalSupply;
        bytes32 merkleRoot;
    }

    mapping(uint256 => TokenType) public tokenTypes;
    mapping (uint256 => mapping(address => uint256)) public hasMinted;
    uint256 public launchpassId;
    string public name;
    string public symbol;
    string private baseURI;

    constructor(
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner,
        InitialParameters memory initialParameters
    ) ERC1155(initialParameters.uri) PaymentSplitter(_payees, _shares) {
        name = initialParameters.name;
        symbol = initialParameters.symbol;
        baseURI = initialParameters.uri;
        launchpassId = initialParameters.launchpassId;
        uint256 _id = initialParameters.id;
        tokenTypes[_id].maxSupply = initialParameters.maxSupply;
        tokenTypes[_id].maxPerWallet = initialParameters.maxPerWallet;
        tokenTypes[_id].maxPerTransaction = initialParameters.maxPerTransaction;
        tokenTypes[_id].preSalePrice = initialParameters.preSalePrice;
        tokenTypes[_id].pubSalePrice = initialParameters.pubSalePrice;
        tokenTypes[_id].totalSupply = 0;
        tokenTypes[_id].saleIsActive = false;
        tokenTypes[_id].preSaleIsActive = false;
        tokenTypes[_id].supplyLock = false;
        tokenTypes[_id].creator = msg.sender;
        transferOwnership(_owner);
    }

    function uri(uint256 _id)
        public
        view                
        override
        returns (string memory)
    {
        require(tokenTypes[_id].creator != address(0), "Token does not exists");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _id.toString()))
                : baseURI;
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function totalSupply(
        uint256 _id
    ) public view returns (uint256) {
        return tokenTypes[_id].totalSupply;
    }

    function maxSupply(
        uint256 _id
    ) public view returns (uint24) {
        return tokenTypes[_id].maxSupply;
    }

    function preSalePrice(
        uint256 _id
    ) public view returns (uint72) {
        return tokenTypes[_id].preSalePrice;
    }

    function pubSalePrice(
        uint256 _id
    ) public view returns (uint72) {
        return tokenTypes[_id].pubSalePrice;
    }

    function maxPerWallet(
        uint256 _id
    ) public view returns (uint24) {
        return tokenTypes[_id].maxPerWallet;
    }

    function maxPerTransaction(
        uint256 _id
    ) public view returns (uint24) {
        return tokenTypes[_id].maxPerTransaction;
    }

    function preSaleIsActive(
        uint256 _id
    ) public view returns (bool) {
        return tokenTypes[_id].preSaleIsActive;
    }

    function supplyLock(
        uint256 _id
    ) public view returns (bool) {
        return tokenTypes[_id].supplyLock;
    }

    function saleIsActive(
        uint256 _id
    ) public view returns (bool) {
        return tokenTypes[_id].saleIsActive;
    }

    function setMaxSupply(uint256 _id, uint24 _supply) public onlyOwner {
        require(!tokenTypes[_id].supplyLock, "Supply is locked.");
       tokenTypes[_id].maxSupply = _supply;
    }

    function lockSupply(uint256 _id) public onlyOwner {
        tokenTypes[_id].supplyLock = true;
    }

    function setPreSalePrice(uint256 _id, uint72 _price) public onlyOwner {
        tokenTypes[_id].preSalePrice = _price;
    }

    function setPublicSalePrice(uint256 _id, uint72 _price) public onlyOwner {
        tokenTypes[_id].pubSalePrice = _price;
    }

    function setMaxPerWallet(uint256 _id, uint24 _quantity) public onlyOwner {
        tokenTypes[_id].maxPerWallet = _quantity;
    }

    function setMaxPerTransaction(uint256 _id, uint24 _quantity) public onlyOwner {
        tokenTypes[_id].maxPerTransaction = _quantity;
    }

    function setRoot(uint256 _id, bytes32 _root) public onlyOwner {
        tokenTypes[_id].merkleRoot = _root;
    }

    function setSaleState(uint256 _id, bool _isActive) public onlyOwner {
        tokenTypes[_id].saleIsActive = _isActive;
    }

    function setPreSaleState(uint256 _id, bool _isActive) public onlyOwner {
        require(tokenTypes[_id].merkleRoot != "", "Merkle root is undefined.");
        tokenTypes[_id].preSaleIsActive = _isActive;
    }

    function verify(uint256 _id, bytes32 leaf, bytes32[] memory proof) public view returns (bool) {
        bytes32 computedHash = leaf;
        for (uint i = 0; i < proof.length; i++) {
          bytes32 proofElement = proof[i];
          if (computedHash <= proofElement) {
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
          } else {
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
          }
        }
        return computedHash == tokenTypes[_id].merkleRoot;
    }

    function createType(
        uint256 _id,
        uint24 _maxSupply,
        uint24 _maxPerWallet,
        uint24 _maxPerTransaction,
        uint72 _preSalePrice,
        uint72 _pubSalePrice
    ) public onlyOwner {
        require(tokenTypes[_id].creator == address(0), "token _id already exists");
        tokenTypes[_id].maxSupply = _maxSupply;
        tokenTypes[_id].maxPerWallet = _maxPerWallet;
        tokenTypes[_id].maxPerTransaction = _maxPerTransaction;
        tokenTypes[_id].preSalePrice = _preSalePrice;
        tokenTypes[_id].pubSalePrice = _pubSalePrice;
        tokenTypes[_id].totalSupply = 0;
        tokenTypes[_id].saleIsActive = false;
        tokenTypes[_id].preSaleIsActive = false;
        tokenTypes[_id].supplyLock = false;
        tokenTypes[_id].creator = msg.sender;
    }

    function mint(
        uint256 _id,
        bytes memory _data,
        uint256 _quantity,
        bytes32[] memory proof
    ) public payable nonReentrant {
        uint _maxPerWallet = tokenTypes[_id].maxPerWallet;
        uint256 _currentSupply = tokenTypes[_id].totalSupply;
        require(tokenTypes[_id].saleIsActive, "Sale is not active.");
        require(_currentSupply + _quantity <= tokenTypes[_id].maxSupply, "Requested quantity would exceed total supply.");
        if(tokenTypes[_id].preSaleIsActive) {
            require(tokenTypes[_id].preSalePrice * _quantity <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= _maxPerWallet, "Exceeds wallet presale limit.");
            uint256 mintedAmount = hasMinted[_id][msg.sender] + _quantity;
            require(mintedAmount <= _maxPerWallet, "Exceeds per wallet presale limit.");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _id));
            require(verify(_id, leaf, proof), "You are not whitelisted.");
            hasMinted[_id][msg.sender] = mintedAmount;
        } else {
            require(tokenTypes[_id].pubSalePrice * _quantity <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= tokenTypes[_id].maxPerTransaction, "Exceeds per transaction limit for public sale.");
        }
        _mint(msg.sender, _id, _quantity, _data);
        tokenTypes[_id].totalSupply = _currentSupply + _quantity;
    }

    function reserve(uint256 _id, bytes memory _data, address _address, uint256 _quantity) public onlyOwner nonReentrant {
        uint256 _currentSupply = tokenTypes[_id].totalSupply;
        require(_currentSupply + _quantity <= tokenTypes[_id].maxSupply, "Requested quantity would exceed total supply.");
        tokenTypes[_id].totalSupply = _currentSupply + _quantity;
        _mint(_address, _id, _quantity, _data);
    }
}
