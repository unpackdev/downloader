// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Strings.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./ERC721Enumerable.sol";

import "./Types.sol";
import "./IStradivarius.sol";

contract Stradivarius is ERC721Enumerable, AccessControl {
  using Strings for uint256;
  using Counters for Counters.Counter;

  bytes32 public constant OWNER_ROLE = keccak256("OWNER");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER");
  uint8 private constant TOKEN_FETCH_LIMIT = 100;

  mapping(uint256 => uint256) public nextTokenIds;
  mapping(uint256 => uint256) public minTokenIds;
  mapping(uint256 => uint256) public totalSupplies;
  uint256 public lastTier = 3;

  string public baseUri;

  address private _owner;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseUri_
  ) ERC721(name_, symbol_) {
    _owner = msg.sender;
    _grantRole(OWNER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);

    baseUri = baseUri_;

    nextTokenIds[1] = 1;
    nextTokenIds[2] = 2;
    nextTokenIds[3] = 33;

    minTokenIds[1] = 1;
    minTokenIds[2] = 2;
    minTokenIds[3] = 33;

    totalSupplies[1] = 1;
    totalSupplies[2] = 31;
    totalSupplies[3] = 93;
  }

  // ============= QUERY

  function supportsInterface(bytes4 interfaceId_)
    public
    view
    override(AccessControl, ERC721Enumerable)
    returns (bool)
  {
    return
      interfaceId_ == type(IStradivarius).interfaceId ||
      super.supportsInterface(interfaceId_);
  }


  /**
   * @dev Returns if the tokenId has been minted. Note that it may have been burned.
   *      To check the existence of the token, use ownerOf().
   */
  function isTokenMinted(uint256 tokenId_) public view returns (bool) {
    uint256 tier = tokenIdToTier(tokenId_);
    return tokenId_ < nextTokenIds[tier];
  }

  function tokenURI(uint256 tokenId_)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId_), "Stradivarius: URI query for nonexistent token");
    return string(abi.encodePacked(baseUri, tokenId_.toString()));
  }

  function getTierInfo() public view returns (TierInfo[] memory) {
    TierInfo[] memory infoArr = new TierInfo[](lastTier);
    for (uint256 i = 1; i <= lastTier; i++) {
      infoArr[i - 1] = TierInfo({
        nextTokenId: nextTokenIds[i],
        minTokenId: minTokenIds[i],
        totalSupply: totalSupplies[i]
      });
    }
    return infoArr;
  }

  function tokenIdToTier(uint256 tokenId_) public view returns (uint256) {
    require(
      minTokenIds[1] <= tokenId_ && tokenId_ < minTokenIds[lastTier] + totalSupplies[lastTier],
      "Stradivarius: tier query for nonexistent token"
    );
    for (uint256 i = 2; i <= lastTier; i++) {
      if (tokenId_ < minTokenIds[i]) return i - 1;
    }
    return lastTier;
  }

  /**
   * @dev Required to be recognized as the owner of the collection on OpenSea.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Returns the token IDs of the owner, starting at the `offset_` ending at `offset_ + limit_ - 1`
   * @param owner_ address of the owner
   * @param offset_ index offset to start enumerating within the ownedTokens list of the owner
   * @param limit_ max number of IDs to fetch
   */
  function tokensOf(
    address owner_,
    uint256 offset_,
    uint256 limit_
  ) public view returns (uint256[] memory) {
    uint256 balance = ERC721.balanceOf(owner_);
    require(limit_ <= TOKEN_FETCH_LIMIT, "Stradivarius: limit too large");
    require(offset_ < balance, "Stradivarius: invalid offset");

    uint256 numToReturn = (offset_ + limit_ <= balance) ? limit_ : balance - offset_;
    uint256[] memory ownedTokens = new uint256[](numToReturn);
    for (uint256 i = 0; i < numToReturn; i++) {
      ownedTokens[i] = tokenOfOwnerByIndex(owner_, offset_ + i);
    }
    return ownedTokens;
  }

  // ============= TX

  function setBaseURI(string calldata baseUri_) public onlyRole(OWNER_ROLE) {
    require(bytes(baseUri_).length > 0, "Stradivarius: cannot set as an empty string");
    baseUri = baseUri_;
  }

  function addTier(uint256 totalSupply) public onlyRole(OWNER_ROLE) {
    require(totalSupply > 0, "Stradivarius: invalid total supply");
    uint256 newTier = lastTier + 1;
    minTokenIds[newTier] = minTokenIds[lastTier] + totalSupplies[lastTier];
    nextTokenIds[newTier] = minTokenIds[newTier];
    totalSupplies[newTier] = totalSupply;
    lastTier = newTier;
  }

  function mint(address to_, uint256 tier_) public onlyRole(MINTER_ROLE) returns (uint256) {
    require(1 <= tier_ && tier_ <= lastTier, "Stradivarius: invalid tier");
    uint256 newTokenId = nextTokenIds[tier_];
    uint256 minTokenId = minTokenIds[tier_];
    uint256 totalSupply = totalSupplies[tier_];
    require(newTokenId < minTokenId + totalSupply, "Stradivarius: minting closed");

    nextTokenIds[tier_] += 1;
    _safeMint(to_, newTokenId);

    return newTokenId;
  }

  function mintMultiple(address to_, uint256 tier_, uint256 amount_)
    public
    onlyRole(MINTER_ROLE)
    returns (uint256[] memory)
  {
    require(1 <= amount_ && amount_ <= totalSupplies[tier_], "Stradivarius: invalid amount");

    uint256 tierMaxTokenId = minTokenIds[tier_] + totalSupplies[tier_] - 1;
    require(nextTokenIds[tier_] <= tierMaxTokenId, "Stradivarius: minting closed");
    if (nextTokenIds[tier_] + amount_ - 1 > tierMaxTokenId) {
      amount_ = tierMaxTokenId - nextTokenIds[tier_] + 1;
    }

    uint256[] memory tokenIds = new uint256[](amount_);
    for (uint256 i = 0; i < amount_; i++) {
      tokenIds[i] = mint(to_, tier_);
    }
    return tokenIds;
  }

  function destroy(address payable to_) public onlyRole(OWNER_ROLE) {
    selfdestruct(to_);
  }
}
