// contracts/MonsterMates.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Ownable.sol";

import "./console.sol";

interface MonsterMatesTypes {
  struct MonsterMate {
    uint256 dna;
  }
}

contract MonsterMates is ERC721Enumerable, Ownable, ReentrancyGuard {
  mapping(uint256 => MonsterMatesTypes.MonsterMate) internal monsters;

  using Strings for uint256;

  using Counters for Counters.Counter;
  Counters.Counter public _tokenIds;
  Counters.Counter public _reservedTokenIds;

  string private baseURI;

  uint8 private constant MAX_PER_ADDRESS = 10;
  uint8 private constant FOUNDERS_RESERVE_AMOUNT = 200;
  uint64 private constant MAX_MONSTER_MATES = 10000;
  uint64 private constant MAX_PUBLIC_MONSTERS =
    MAX_MONSTER_MATES - FOUNDERS_RESERVE_AMOUNT;
  uint256 private constant MINT_PRICE = 0.02 ether;

  bool private isEarlySaleActive = false;
  bool private isPublicSaleActive = false;

  bytes32 private root;

  mapping(address => uint256) private allowListClaimed;
  mapping(address => uint256) private founderMintCountsRemaining;

  constructor(string memory _initBaseURI, bytes32 _root) ERC721("Monster Mates", "MONSTERMATES") {
    baseURI = _initBaseURI;
    root = _root;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setIsEarlySaleActive(bool _isEarlySaleActive) external onlyOwner {
    isEarlySaleActive = _isEarlySaleActive;
  }

  function getIsEarlySaleActive() public view returns (bool) {
    return isEarlySaleActive;
  }

  function setIsPublicSaleActive(bool _isPublicSaleActive) external onlyOwner {
    isPublicSaleActive = _isPublicSaleActive;
  }

  function getIsPublicSaleActive() public view returns (bool) {
    return isPublicSaleActive;
  }

  function allocateFounderMint(address _addr, uint256 _count)
    public
    onlyOwner
    nonReentrant
  {
    founderMintCountsRemaining[_addr] = _count;
  }

  function verify(
    bytes32 leaf,
    bytes32[] memory proof
  ) internal view returns (bool) {
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == root;
  }

  function earlyMint(
    bytes32 leaf,
    bytes32[] memory proof,
    uint256 _count
  ) external payable nonReentrant returns (uint256, uint256) {
    require(isEarlySaleActive, "Early access not open");
    require(verify(leaf, proof), "Validation Failed");
    require(_count > 0 && _count <= MAX_PER_ADDRESS, "Invalid Monster count");
    require(
      _tokenIds.current() + _count <= MAX_PUBLIC_MONSTERS,
      "All Monsters have been minted"
    );
    require(
      allowListClaimed[msg.sender] + _count <= MAX_PER_ADDRESS,
      "Purchase exceeds max allowed"
    );
    require(_count * MINT_PRICE == msg.value, "Incorrect amount of ether sent");

    uint256 firstMintedId = _tokenIds.current() + 1;

    for (uint256 i = 0; i < _count; i++) {
      _tokenIds.increment();
      allowListClaimed[msg.sender] += 1;
      mint(_tokenIds.current());
    }

    return (firstMintedId, _count);
  }

  function publicMint(uint256 _count)
    external
    payable
    nonReentrant
    returns (uint256, uint256)
  {
    require(isPublicSaleActive, "Public sale not open");
    require(_count > 0 && _count <= MAX_PER_ADDRESS, "Invalid Monster count");
    require(
      _tokenIds.current() + _count <= MAX_PUBLIC_MONSTERS,
      "All Monsters have been minted"
    );
    require(
      allowListClaimed[msg.sender] + _count <= MAX_PER_ADDRESS,
      "Purchase exceeds max allowed"
    );
    require(_count * MINT_PRICE == msg.value, "Incorrect amount of ether sent");

    uint256 firstMintedId = _tokenIds.current() + 1;

    for (uint256 i = 0; i < _count; i++) {
      _tokenIds.increment();
      allowListClaimed[msg.sender] += 1;
      mint(_tokenIds.current());
    }

    return (firstMintedId, _count);
  }

  function founderMint(uint256 _count)
    public
    nonReentrant
    returns (uint256, uint256)
  {
    require(_count > 0, "Count must be greater than zero");
    require(
      _reservedTokenIds.current() + _count <= FOUNDERS_RESERVE_AMOUNT,
      "Reserved Monsters all minted"
    );
    require(
      founderMintCountsRemaining[msg.sender] >= _count,
      "Cannot mint this many Monsters"
    );

    uint256 firstMintedId = MAX_PUBLIC_MONSTERS + _tokenIds.current() + 1;

    for (uint256 i = 0; i < _count; i++) {
      _reservedTokenIds.increment();
      mint(MAX_PUBLIC_MONSTERS + _reservedTokenIds.current());
    }

    founderMintCountsRemaining[msg.sender] -= _count;
    return (firstMintedId, _count);
  }

  function mint(uint256 tokenId) internal {
    MonsterMatesTypes.MonsterMate memory monster;
    monster.dna = uint256(
      keccak256(abi.encodePacked(tokenId, msg.sender, block.difficulty))
    );

    _safeMint(msg.sender, tokenId);
    monsters[tokenId] = monster;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "URI query for nonexistent token");

    return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
  }

  function withdraw() external nonReentrant onlyOwner {
    (bool devWithdrawal, ) = payable(
      0x32908fe8Ab1E385C8b3Fb758e29873f6a95D2FF6
    ).call{value: (address(this).balance * 10) / 100}("");
    require(devWithdrawal, "Dev Withdrawal Error");

    (bool ownerWithdrawal, ) = payable(owner()).call{
      value: address(this).balance
    }("");
    require(ownerWithdrawal, "Owner Withdrawal Error");
  }
}
