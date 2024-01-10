// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract TheResidenceDAO is ERC721, Ownable {
    using Strings for uint256;

    enum Status { SALE_NOT_LIVE, PRESALE_LIVE, SALE_LIVE }

    uint256 public constant MAX_PER_TX_GLOBAL = 1;
    uint256 public constant MAX_PER_TX_CITY = 4;
    uint256 public constant MAX_PER_TX_PRESALE_GLOBAL = 1;
    uint256 public constant MAX_PER_TX_PRESALE_CITY = 4;
    uint256 public constant GLOBAL_PRICE = 1.25 ether;
    uint256 public constant GLOBAL_MAX_SUPPLY = 500;

    Status public state;
    string public baseURI;

    // CITY CHANGEABLE
    uint256 public cityPrice;
    uint256 public citySupply;
    uint256 public cityCount;
    uint256 public cityNumber = 0;
    uint256 public whitelistAmount = 4;
    uint256 public globalMintCounter;
    uint256 public cityMintCounter;

    uint256 private _reservedTeamTokens;
    bytes32 private _merkleProof;
    mapping(address => uint256) _citiesMinted;
    mapping(address => bool) _globalMinted;
    mapping(uint16 => bool) _globalTokenIds;

    constructor() ERC721("The Residence DAO", "TRD") { }

    function mintGlobalPresale(bytes32[] calldata proof) external payable {
        require(state == Status.PRESALE_LIVE, "Residence DAO: Sale Not Live");
        require(msg.sender == tx.origin, "Residence DAO: Contract Interaction Not Allowed");
        require(globalMintCounter <= GLOBAL_MAX_SUPPLY, "Residence DAO: Exceed Max Supply");
        require(msg.value >= GLOBAL_PRICE, "Residence DAO: Insufficient ETH");

        if(state == Status.PRESALE_LIVE) {
            require(MerkleProof.verify(proof, _merkleProof, keccak256(abi.encodePacked(msg.sender))), "Residence DAO: Not Whitelisted");
            require(!_globalMinted[msg.sender], "Residence DAO: Exceeds Max Per Wallet");
            _globalMinted[msg.sender] = true;
        }

        uint256 id = globalMintCounter;
        _safeMint(msg.sender, id);
        globalMintCounter++;
    }

    function mintGlobal() external payable {
        require(state == Status.SALE_LIVE, "Residence DAO: Sale Not Live");
        require(msg.sender == tx.origin, "Residence DAO: Contract Interaction Not Allowed");
        require(globalMintCounter <= GLOBAL_MAX_SUPPLY, "Residence DAO: Exceed Max Supply");
        require(msg.value >= GLOBAL_PRICE, "Residence DAO: Insufficient ETH");

        uint256 id = globalMintCounter;
        _safeMint(msg.sender, id);
        globalMintCounter++;

    }

    function mintCityPresale(uint256 quantity, bytes32[] calldata proof) external payable {
        require(state == Status.PRESALE_LIVE, "Residence DAO: Sale Not Live");
        require(msg.sender == tx.origin, "Residence DAO: Contract Interaction Not Allowed");
        require(cityCount + quantity <= citySupply, "Residence DAO: Exceed Max Supply");
        require(quantity <= MAX_PER_TX_CITY, "Residence DAO: Exceeds Max Per TX");
        require(msg.value >= cityPrice * quantity, "Residence DAO: Insufficient ETH");

        if(state == Status.PRESALE_LIVE) {
            require(MerkleProof.verify(proof, _merkleProof, keccak256(abi.encodePacked(msg.sender))), "Residence DAO: Not Whitelisted");
            require(_citiesMinted[msg.sender] + quantity <= whitelistAmount, "Residence DAO: Exceeds Max Per Wallet");
            _citiesMinted[msg.sender] += quantity;
        }
        for (uint256 index = 0; index < quantity; index++) {
            uint256 id = cityMintCounter + GLOBAL_MAX_SUPPLY;
            _safeMint(msg.sender, id);
            cityMintCounter++;
            cityCount++;
        }
    }

    function mintCity(uint256 quantity) external payable {
        require(state == Status.SALE_LIVE, "Residence DAO: Sale Not Live");
        require(msg.sender == tx.origin, "Residence DAO: Contract Interaction Not Allowed");
        require(cityCount + quantity <= citySupply, "Residence DAO: Exceed Max Supply");
        require(quantity <= MAX_PER_TX_CITY, "Residence DAO: Exceeds Max Per TX");
        require(msg.value >= cityPrice * quantity, "Residence DAO: Insufficient ETH");

        if(state == Status.SALE_LIVE) {
            require(quantity <= 4, "Residence DAO: Exceeds Max Per Txn");
        }

        for (uint256 index = 0; index < quantity; index++) {
            uint256 id = cityMintCounter + GLOBAL_MAX_SUPPLY;
            _safeMint(msg.sender, id);
            cityMintCounter++;
            cityCount++;
        }
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(globalMintCounter + quantity <= GLOBAL_MAX_SUPPLY, "Residence DAO: Exceed Max Supply");

        for (uint256 index = 0; index < quantity; index++) {
            uint256 id = globalMintCounter;
            _safeMint(msg.sender, id);
            globalMintCounter++;
        }
    }

    function setSaleState(Status _state) external onlyOwner {
        state = _state;
    }

    function updateBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setCityPrice(uint256 _cityPrice) external onlyOwner {
        cityPrice = _cityPrice;
    }

    function setMerkleProof(bytes32 _proof) external onlyOwner {
        _merkleProof = _proof;
    }

    function setCitySupply(uint256 _citySupply) external onlyOwner {
        citySupply = _citySupply;
    }

    function setCityCount(uint256 _cityCount) public onlyOwner {
        cityCount = _cityCount;
    }

    function setWhitelistAmount(uint256 _whitelistAmount) public onlyOwner {
        whitelistAmount = _whitelistAmount;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), '.json'));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}