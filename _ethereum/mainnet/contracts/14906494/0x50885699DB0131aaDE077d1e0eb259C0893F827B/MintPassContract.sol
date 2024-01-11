// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract MintPassContract is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;

    struct InitialParameters {
        uint256 id;
        uint256 launchpassId;
        string name;
        string symbol;
        string uri;
        uint256 maxSupply;
    }

    struct TokenType {
        bool valid;
        bool supplyLock;
        uint256 totalSupply;
        uint256 maxSupply;
        bytes32 merkleRoot;
    }

    string private baseURI;
    address private burnerContract;
    string public name;
    string public symbol;
    uint256 public launchpassId;

    mapping(uint256 => TokenType) public tokenTypes;
    mapping (uint256 => mapping(address => uint256)) public hasClaimed;

    event SetBaseURI(string indexed _uri);

    modifier onlyBurner() {
        require(msg.sender == burnerContract, "Not authorized to perform this action");
        _;
    }

    constructor(
        address _owner,
        address _deployer,
        uint256 _initialShare,
        InitialParameters memory initialParameters
    ) nonReentrant ERC1155(initialParameters.uri)  {
        name = initialParameters.name;
        symbol = initialParameters.symbol;
        baseURI = initialParameters.uri;
        launchpassId = initialParameters.launchpassId;
        uint256 _id = initialParameters.id;
        uint256 _maxSupply = initialParameters.maxSupply;
        tokenTypes[_id].maxSupply = _maxSupply;
        tokenTypes[_id].totalSupply = 0;
        tokenTypes[_id].supplyLock = false;
        emit SetBaseURI(baseURI);
        transferOwnership(_owner);
        if (_initialShare > 0) {
            uint256 _share = _maxSupply * _initialShare/100;
            _mint(_owner, _id, _share, "");
            _mint(_deployer, _id, _share, "");
        }
        
    }

    function totalSupply(
        uint256 _id
    ) public view returns (uint256) {
        return tokenTypes[_id].totalSupply;
    }

    function maxSupply(
        uint256 _id
    ) public view returns (uint256) {
        return tokenTypes[_id].maxSupply;
    }

    function uri(uint256 _id)
        public
        view                
        override
        returns (string memory)
    {
        require(
            tokenTypes[_id].valid,
            "URI requested for invalid type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _id.toString()))
                : baseURI;
    }

    function setMaxSupply(uint256 _id, uint256 _supply) public onlyOwner {
        require(!tokenTypes[_id].supplyLock, "Supply is locked.");
       tokenTypes[_id].maxSupply = _supply;
    }

    function lockSupply(uint256 _id) public onlyOwner {
        tokenTypes[_id].supplyLock = true;
    }

    function setRoot(uint256 _id, bytes32 _root) public onlyOwner {
        tokenTypes[_id].merkleRoot = _root;
    }

    function createType(
        uint256 _id,
        uint256 _maxSupply
    ) public onlyOwner {
        require(!tokenTypes[_id].supplyLock, "Supply is locked.");
        require(tokenTypes[_id].valid == false, "token _id already exists");
        tokenTypes[_id].valid = true;
        tokenTypes[_id].maxSupply = _maxSupply;
    }

    function setBurnerAddress(address _address)
        external
        onlyOwner
    {
        burnerContract = _address;
    }

    function burnForAddress(uint256 _id, uint256 _quantity, address _address)
        external onlyBurner
    {
        _burn(_address, _id, _quantity);
    }

    function mintBatch(uint256 _id, uint256 _quantity)
        external
        onlyOwner
    {
        require(tokenTypes[_id].valid, "Invalid token type");
        require(tokenTypes[_id].totalSupply + _quantity <= tokenTypes[_id].maxSupply, "Requested quantity would exceed total supply.");
        _mint(owner(), _id, _quantity, "");
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
        emit SetBaseURI(baseURI);
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

    function claimable(address _address, uint256 _id, uint256 _maxMint, bytes32[] memory _proof) public view returns (uint256) {
        bytes32 leaf = keccak256(abi.encode(_address, _maxMint));
        if (verify(_id, leaf, _proof)) {
            uint256 _claimable = _maxMint - hasClaimed[_id][_address];
            return _claimable > 0 && _claimable <= _maxMint ? _claimable : 0;
        } else {
            return 0;
        }
    }

    function claim(uint256 _id, bytes memory _data, uint256 _maxMint, uint256 _quantity, bytes32[] memory _proof) public {
        uint256 _currentSupply = tokenTypes[_id].totalSupply;
        require(_currentSupply + _quantity <= tokenTypes[_id].maxSupply, "Requested quantity would exceed total supply.");
        uint256 _claimable = claimable(msg.sender, _id, _maxMint, _proof);
        require(_claimable > 0, "Not eligible.");
        require(_quantity <= _claimable, "Exceeds per wallet presale limit.");
        tokenTypes[_id].totalSupply = _currentSupply + _quantity;
        hasClaimed[_id][msg.sender] = hasClaimed[_id][msg.sender] + _quantity;
        _mint(msg.sender, _id, _quantity, _data);
    }
}