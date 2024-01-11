pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract HomieFaces is ERC721A, Ownable {
    // @dev refer to setProvenance and randomSeedIndex function
    event Provenance(uint256 indexed proveType, bytes32 proveData);

    string private _baseURIextended;

    string private constant ERR_ONLY_EOA = "Only EOA";
    string private constant ERR_MINT_END = "Minting ended";
    string private constant ERR_MINT_NOT_START = "Not started yet";
    string private constant ERR_LIMIT_EXCEED = "Limit exceeded";
    string private constant ERR_WRONG_VALUE = "Value not correct";
    string private constant ERR_NOT_WHITELIST = "Not whitelisted";
    string private constant ERR_ONLY_REDUCE = "Reduce only";

    uint256 public constant PUBLIC_MINTING_LIMIT = 20;
    uint256 public constant MINTING_PRICE = 0.05 ether;
    uint16 public constant MAX_RESERVE = 10;
    uint8 public constant WL_LIMIT = 2;
    uint8 public constant OG_LIMIT = 3;

    uint8 public activeStage = 0;
    bytes32 public whitelistMerkleRoot = 0x0;
    bytes32 public ogMerkleRoot = 0x0;
    uint256 public maxSupply = 4444;

    mapping(address => uint8) public ticketRecord;

    constructor() ERC721A("HomieFaces", "HOMIEFACESNFT") {}

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) 
        external
        onlyOwner 
    {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setOgMerkleRoot(bytes32 _merkleRoot) 
        external
        onlyOwner 
    {
        ogMerkleRoot = _merkleRoot;
    }

    function setActiveStage(uint8 _stage)
        external
        onlyOwner
    {
        activeStage = _stage;
    }

    function reduceMaxSupply(uint256 _maxSupply)
        external
        onlyOwner
    {
        require(_maxSupply >= totalSupply(), ERR_LIMIT_EXCEED);
        require(_maxSupply < maxSupply, ERR_ONLY_REDUCE);
        maxSupply = _maxSupply;
    }

    function whitelistPreSales(uint8 _numberOfTokens, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(msg.sender == tx.origin, ERR_ONLY_EOA);
        require(_numberOfTokens <= WL_LIMIT, ERR_LIMIT_EXCEED);
        require(activeStage >= 1, ERR_MINT_NOT_START);

        uint256 totalSupply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool proofed = MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf);
        require(proofed, ERR_NOT_WHITELIST);
        require(totalSupply + _numberOfTokens <= maxSupply, ERR_LIMIT_EXCEED);
        require(ticketRecord[msg.sender] + _numberOfTokens <= WL_LIMIT
            , ERR_LIMIT_EXCEED);
        require(MINTING_PRICE * _numberOfTokens <= msg.value, ERR_WRONG_VALUE);

        ticketRecord[msg.sender] += _numberOfTokens;
        _safeMint(msg.sender, _numberOfTokens);
    }

    function ogPreSales(uint8 _numberOfTokens, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(msg.sender == tx.origin, ERR_ONLY_EOA);
        require(_numberOfTokens <= OG_LIMIT, ERR_LIMIT_EXCEED);
        require(activeStage >= 1, ERR_MINT_NOT_START);

        uint256 totalSupply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool proofed = MerkleProof.verify(_merkleProof, ogMerkleRoot, leaf);
        require(proofed, ERR_NOT_WHITELIST);
        require(totalSupply + _numberOfTokens <= maxSupply, ERR_LIMIT_EXCEED);
        require(ticketRecord[msg.sender] + _numberOfTokens <= OG_LIMIT
            , ERR_LIMIT_EXCEED);
        require(MINTING_PRICE * _numberOfTokens <= msg.value, ERR_WRONG_VALUE);

        ticketRecord[msg.sender] += _numberOfTokens;
        _safeMint(msg.sender, _numberOfTokens);
    }

    function publicMint(uint _numberOfTokens) public payable {
        require(msg.sender == tx.origin, ERR_ONLY_EOA);

        uint256 totalSupply = totalSupply();
        require(totalSupply < maxSupply,
            ERR_MINT_END);
        require(activeStage >= 2,
            ERR_MINT_NOT_START);
        require(_numberOfTokens <= PUBLIC_MINTING_LIMIT, 
            ERR_LIMIT_EXCEED);
        require(totalSupply + _numberOfTokens <= maxSupply, 
            ERR_LIMIT_EXCEED);
        require(MINTING_PRICE * _numberOfTokens <= msg.value, 
            ERR_WRONG_VALUE);

        _safeMint(msg.sender, _numberOfTokens);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 _numberOfTokens) public onlyOwner {
        require(totalSupply() == 0, ERR_LIMIT_EXCEED);
        require(_numberOfTokens <= MAX_RESERVE, ERR_LIMIT_EXCEED);

        _safeMint(msg.sender, _numberOfTokens);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setProvenance(bytes32 _proveData) public onlyOwner {
        emit Provenance(1, _proveData);
    }

    function randomSeedIndex() external onlyOwner {
        uint256 number = uint(keccak256(
            abi.encodePacked(block.difficulty, block.timestamp)));
        
        bytes32 n = bytes32(number % maxSupply);
            emit Provenance(2, n);
    }
}
