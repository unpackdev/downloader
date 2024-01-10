// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract ILYYW is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_TOKEN_SUPPLY = 10000;
    uint256 public constant MAX_MINTS_PER_PERSON = 3;
    uint256 public constant MAX_RESERVE = 125;

    uint256 public price = 0.09 ether;
    uint    public reserveClaimed = 0;
    bool    public paused = true;
    bytes32 public merkleRoot = 0x0;

    enum EPublicMintStatus {
        CLOSED,
        RESERVED,
        WEIRD_LIST,
        PUBLIC
    }
    EPublicMintStatus public publicMintStatus;

    constructor(string memory _uri) ERC721A("Weirdos", "ILYYW") {
        baseURI = _uri;
    }

    modifier verifySupply(uint256 _numberOfMints) {
        require(tx.origin == msg.sender,                            "We like humans.");
        require(!paused,                                            "Minting is paused.");
        require(_numberOfMints > 0,                                 "Must mint at least 1.");
        require(totalSupply() + _numberOfMints <= MAX_TOKEN_SUPPLY, "Exceeds max token supply.");

        if (msg.sender == owner()) {
            require(_numberMinted(msg.sender) + _numberOfMints <= MAX_MINTS_PER_PERSON + MAX_RESERVE, "Exceeds max mints for owner.");
        } else {
            require(_numberMinted(msg.sender) + _numberOfMints <= MAX_MINTS_PER_PERSON, "Exceeds max mints.");
        }

        _;
    }

    function reservedMint(uint256 _numberOfMints) external onlyOwner verifySupply(_numberOfMints) {
        require(reserveClaimed + _numberOfMints <= MAX_RESERVE, "No reserves left.");
        require(publicMintStatus == EPublicMintStatus.RESERVED, "Reserved mint is closed.");

        reserveClaimed += _numberOfMints;
        _safeMint(msg.sender, _numberOfMints);
    }

    function merkleMint(bytes32[] calldata _merkleProof, uint256 _numberOfMints) public payable verifySupply(_numberOfMints) {
        require(publicMintStatus == EPublicMintStatus.WEIRD_LIST, "Weird list is closed.");
        require(msg.value >= price * _numberOfMints, "Incorrect ether sent." );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Merkle proof.");

        _safeMint(msg.sender, _numberOfMints);
    }

    function mint(uint256 _numberOfMints) public payable verifySupply(_numberOfMints) {
        require(publicMintStatus == EPublicMintStatus.PUBLIC, "Public mint is closed.");
        require(msg.value >= price * _numberOfMints, "Incorrect ether sent." );

        _safeMint(msg.sender, _numberOfMints);
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    function pause(bool _value) external onlyOwner {
        paused = _value;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPublicMintStatus(uint256 _status) external onlyOwner {
        publicMintStatus = EPublicMintStatus(_status);
    }

    function verifyMerkle(bytes32[] calldata _proof, bytes32 _leaf) public view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    string private baseURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }
}
