// contracts/CryptoPoops.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

// OpenZeppelin
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ERC165.sol";
import "./Strings.sol";

import "./CryptoPoopTraits.sol"; 

// Inspired/built on top of open source BGANPUNKS V2
// and the lovable justice-filled Chubbies
contract CryptoPoops is CryptoPoopTraits, AccessControl, ReentrancyGuard {
  using SafeMath for uint8;
  using SafeMath for uint256;
  using Strings for string;

  // Max NFTs total. Due to burning this won't be the max tokenId
  uint public constant MAX_POOPS = 6006;

  // Allow for starting/pausing sale
  bool public hasSaleStarted = false;

  // Delegation to third party contracts
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant REROLLER_ROLE = keccak256("REROLLER_ROLE");

  // Effectively a UUID. Only increments to avoid collisions
  // possible if we were reusing token IDs
  uint internal nextTokenId = 0;

  // Mapping for token URIs
  mapping (uint256 => string) private _tokenURIs;

  // Base URI
  string private _baseTokenURI;

  /*
   *     bytes4(keccak256('setLevelProbabilities(uint8[]')) == 0x63a280a5
   *     bytes4(keccak256('setCategoryOptions(
   *       uint8[],uint8[],uint8[],uint8[],uint8[],uint8[])')) == 0x60b4911a
   *     bytes4(keccak256('getCategoryOptions(uint8,uint8)')) == 0x5e6c82f7
   *     bytes4(keccak256('reRollTraits(uint256,uint8)')) == 0x666644d0
   *     bytes4(keccak256('traitsOf(uint256)')) == 0x5efab6e4
   *
   *     => 0x63a280a5 ^ 0x60b4911a ^ 0x5e6c82f7 ^ 0x666644d0 ^ 0x5efab6e4 == 0x65e6617c
   */
  bytes4 private constant _INTERFACE_ID_ENCODED_TRAITS = 0x65e6617c;

  /*
   * Set up the basics
   *
   * @dev It will NOT be ready to start sale immediately upon deploy
   */
  constructor(string memory baseURI) {
    _baseTokenURI = baseURI;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    // Register the supported interfaces to conform to ERC721
    // and our own encoded traits interface via ERC165
    _registerInterface(_INTERFACE_ID_ENCODED_TRAITS);
  }

  /*
   * Get the tokens owned by _owner
   */
  function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  /*
   * Calculate price for the immediate next NFT minted
   */
  function calculatePrice() public view returns (uint256) {
    require(hasSaleStarted == true, "Sale hasn't started");
    require(totalSupply() < MAX_POOPS,
            "We are at max supply. Burn some in a paper bag...?");

    uint currentSupply = totalSupply();
    if (currentSupply >= 1338) {
      return 69000000000000000;         // 1338-6006:   0.069 ETH
    } else {
      return 42000000000000000;         // 0 - 1337:   0.0420 ETH
    }
  }

  /*
   * Main function for the NFT sale
   *
   * Prerequisites
   *  - Not at max supply
   *  - Sale has started
   */
  function dropPoops(uint256 numCryptoPoops, uint8 boost) external payable nonReentrant {
    require(totalSupply() < MAX_POOPS,
           "We are at max supply. Burn some in a paper bag...?");
    require(numCryptoPoops > 0 && numCryptoPoops <= 20, "You can drop minimum 1, maximum 20 CryptoPoops");
    require(totalSupply().add(numCryptoPoops) <= MAX_POOPS, "Exceeds MAX_POOPS");
    require(hasRole(MINTER_ROLE, msg.sender) || (msg.value >= calculatePrice().mul(numCryptoPoops)),
           "Ether value sent is below the price");
    require(hasRole(MINTER_ROLE, msg.sender) || (boost == 0),
            "If you'd like a contract to be whitelisted for minting or boost, say hi in the Discord");

    for (uint i = 0; i < numCryptoPoops; i++) {
      uint mintId = nextTokenId++;
      _safeMintWithTraits(msg.sender, mintId, boost);
    }
  }

  /*
   * Combines minting and trait generation in one place, so all CryptoPoops
   * get assigned traits correctly.
   */
  function _safeMintWithTraits(address _to, uint256 _mintId, uint8 _boost) internal {
    _safeMint(_to, _mintId);

    uint64 encodedTraits = _assignTraits(_mintId, _boost);
    emit TraitAssigned(_to, _mintId, encodedTraits);
  }

  /*
   * Performs the random number generation for trait assignment
   * and stores the result in the contract
   */
  function _assignTraits(uint256 _tokenId, uint8 _boost) internal returns (uint64) {
    uint8[NUM_CATEGORIES] memory assignedTraits;
    uint8 rarityLevel;

    for (uint8 i = 0; i < NUM_CATEGORIES; i++) {
      rarityLevel = randomLevel() + _boost;
      if (rarityLevel >= NUM_LEVELS) {
        rarityLevel = NUM_LEVELS - 1;
      }
      assignedTraits[i] = randomTrait(rarityLevel, i);
    }

    uint64 encodedTraits = encodeTraits(assignedTraits);
    _tokenTraits[_tokenId] = encodedTraits;
    return encodedTraits;
  }

  /*
   * Allows a smart contract to re-roll traits if it's been approved as a reroller.
   */
  function reRollTraits(uint256 _tokenId, uint8 _boost) public payable nonReentrant {
    require(_exists(_tokenId), "Token doesn't exist");
    require(msg.sender == ERC721.ownerOf(_tokenId), "Only token owner can re-roll");
    require(hasRole(REROLLER_ROLE, msg.sender),
      "If you'd like a contract to be whitelisted for re-rolls, say hi in the Discord");

    uint64 encodedTraits = _assignTraits(_tokenId, _boost);
    emit TraitAssigned(msg.sender, _tokenId, encodedTraits);
  }

  /*
   * Allows approved third party smart contracts to burn CryptoPoops
   *
   * Emits an ERC-721 {Transfer} event
   */
  function burnToken(uint256 _tokenId) public payable nonReentrant {
    require(hasRole(BURNER_ROLE, msg.sender), "Not approved for burning");
    require(_exists(_tokenId), "Token doesn't exist");
    require(msg.sender == ERC721.ownerOf(_tokenId), "Only token owner can burn");

    // Burn token via ERC-721
    _burn(_tokenId);

    // Successful burn, clear traits
    delete _tokenTraits[_tokenId];
  }

  /*
   * Get traits of an individual token. Might come in handy
   */
  function traitsOf(uint256 _tokenId) external view returns (uint64) {
    require(_exists(_tokenId), "Traits query for nonexistent token");
    return _tokenTraits[_tokenId];
  }

  /*
   * Only valid before the sales starts, for giveaways/team thank you's
   */
  function reserveGiveaway(uint256 numCryptoPoops) public onlyOwner {
    uint currentSupply = totalSupply();
    require(totalSupply().add(numCryptoPoops) <= 70, "Exceeded giveaway supply");
    require(hasSaleStarted == false, "Sale has already started");
    uint256 index;
    // Reserved for people who helped this project and giveaways
    for (index = 0; index < numCryptoPoops; index++) {
      nextTokenId++;
      _safeMint(owner(), currentSupply + index);
    }
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view override(ERC165, AccessControl) returns (bool) {
      return AccessControl.supportsInterface(interfaceId) ||
             ERC165.supportsInterface(interfaceId);
  }

  // God Mode
  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function baseURI() public view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function startSale() public onlyOwner {
    hasSaleStarted = true;
  }

  function pauseSale() public onlyOwner {
    hasSaleStarted = false;
  }

  function withdrawAll() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Nonexistent token");

    if (bytes(_tokenURIs[tokenId]).length != 0) {
      return _tokenURIs[tokenId];
    }
    return string(abi.encodePacked(_baseTokenURI, Strings.uint2str(tokenId), "/index.json"));
  }

  // Handy while calculating XOR of all function selectors
  //function calculateSelector() public pure returns (bytes4) {
  //  return type(IAccessControl).interfaceId;
  //}
}
