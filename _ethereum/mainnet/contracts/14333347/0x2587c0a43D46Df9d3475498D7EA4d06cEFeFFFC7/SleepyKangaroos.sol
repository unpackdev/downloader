// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract SleepyKangaroos is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using MerkleProof for bytes32[];
    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_SUPPLY = 8765;
    uint256 public constant MAX_PUBLIC_PURCHASE = 5;
    uint256 public constant MAX_PRESALE_PURCHASE = 3;

    uint256 private _price = 0.06 ether;
    uint256 private _reserved = 150;

    string public SK_PROVENANCE;
    string private baseURI;

    bool public _isSaleActive = false;
    bool public _isPresaleActive = false;

    bytes32 public merkleRoot;
    mapping(address => uint8) private _presaleList;

    constructor() ERC721('Sleepy Kangaroos', 'SK') {}

    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getReservedRemaining() public view returns (uint256) {
        return _reserved;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        SK_PROVENANCE = provenanceHash;
    }

    function setPresaleState(bool newState) public onlyOwner {
        _isPresaleActive = newState;
    }

    function setSaleState(bool newState) public onlyOwner {
        _isSaleActive = newState;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    modifier mintCompliance(uint256 _numTokens, uint256 _maxPurchase) {
        require(
            _numTokens > 0 && _numTokens <= _maxPurchase,
            'invalid mint number'
        );
        require(
            _tokenIdCounter.current() + _numTokens <= MAX_SUPPLY - _reserved,
            'not enough tokens left'
        );
        _;
    }

    function mintPresaleList(bytes32[] calldata proof, uint8 _numTokens)
        external
        payable
        mintCompliance(_numTokens, MAX_PRESALE_PURCHASE)
    {
        address account = msg.sender;
        require(_isPresaleActive, 'presale inactive');
        require(msg.value >= _price * _numTokens, 'insufficient funds');
        require(
            MerkleProof.verify(proof, merkleRoot, _leaf(account)),
            'invalid proof'
        );
        require(
            _presaleList[account] + _numTokens <= MAX_PRESALE_PURCHASE,
            'minted max presale'
        );
        _presaleList[account] += _numTokens;
        _mintLoop(account, _numTokens);
    }

    function mint(uint8 _numTokens)
        external
        payable
        mintCompliance(_numTokens, MAX_PUBLIC_PURCHASE)
    {
        require(_isSaleActive, 'sale inactive');
        require(msg.value >= _price * _numTokens, 'insufficient funds');
        _mintLoop(msg.sender, _numTokens);
    }

    function claimReserved(uint8 _numTokens, address _receiver)
        external
        onlyOwner
    {
        require(_numTokens <= _reserved, 'not enough reserved left');
        _reserved = _reserved - _numTokens;
        _mintLoop(_receiver, _numTokens);
    }

    function _mintLoop(address _receiver, uint8 _numTokens) internal {
        for (uint256 i = 0; i < _numTokens; i++) {
            _tokenIdCounter.increment();
            _safeMint(_receiver, _tokenIdCounter.current());
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
