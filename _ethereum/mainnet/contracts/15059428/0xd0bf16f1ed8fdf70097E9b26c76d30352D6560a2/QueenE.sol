// SPDX-License-Identifier: MIT

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

import "./draft-EIP712.sol";
import "./EnumerableSet.sol";

import "./RoyalLibrary.sol";
import "./IQueenTraits.sol";
import "./IQueenE.sol";
import "./IQueenPalace.sol";
import "./QueenParliament.sol";
import "./IProxyRegistry.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./IQueenLab.sol";

contract QueenE is IQueenE, QueenParliament {
  event FinalArtSet(uint256 indexed queeneId, string artUri);
  event QueenEBurned(uint256 indexed queeneId);

  event SirAwarded(uint256 indexed queeneId, address sirAddress);
  event MuseumAwarded(uint256 indexed queeneId, address museumAddress);

  event StorageLocked();
  event LabLocked();
  event MinterLocked();

  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;
  using RoyalLibrary for string;

  // if trait storage contract can be updated
  bool public isTraitStorageLocked;
  // if lab contract can be updated
  bool public isLabLocked;
  // if minter contract can be updated
  bool public isMinterLocked;

  // QueenE id that will be used for next auction
  uint256 public override _currentAuctionQueenE;

  string private _ipfsProvider = "ipfs://";
  string private _ipfsContractURIHash;

  // OpenSea's Proxy Registry
  IProxyRegistry public immutable proxyRegistry;

  /************************** vMODIFIERS REGION *************************************************** */

  /**
   * @notice Require that the minter has not been locked.
   */
  modifier whenMinterNotLocked() {
    require(!isMinterLocked, "QueenE::Minter locked");
    _;
  }

  /**
   * @notice Require that the QueenE Trait Storage has not been locked.
   */
  modifier whenTraitStorageNotLocked() {
    require(!isTraitStorageLocked, "QueenE::Storage locked");
    _;
  }

  /**
   * @notice Require that the QueenE Lab has not been locked.
   */
  modifier whenLabNotLocked() {
    require(!isLabLocked, "QueenE::Lab locked");
    _;
  }

  /**
   * @notice Require that the sender is a Sir or DAO Executor.
   */
  modifier onlySirOrDAO() {
    isSirOrDAO();
    _;
  }

  /**
   *  Return if given address have Sir Title
   *
   */
  function isSirOrDAO() private view {
    require(
      IsSir(msg.sender) || msg.sender == queenPalace.daoExecutor(),
      "QueenE::Not sir"
    );
  }

  function _isLabNotLocked() private view {
    require(!isLabLocked, "QueenE::Lab locked");
  }

  /************************** ^MODIFIERS REGION *************************************************** */

  /************************** vCONSTRUCTOR REGION *************************************************** */

  constructor(
    IQueenPalace _queenPalace,
    address[] memory founders,
    IProxyRegistry _proxyRegistry,
    string memory _ipfsProviderUri,
    string memory _ipfsContractHash
  ) ERC721("QueenE", "QUEENE") EIP712("QueenE", "1.0") {
    _registerInterface(type(IQueenE).interfaceId);
    queenPalace = _queenPalace;

    _currentAuctionQueenE = 1;

    _ipfsProvider = _ipfsProviderUri;
    _ipfsContractURIHash = _ipfsContractHash;

    for (uint256 idx = 0; idx < founders.length; idx++)
      sirs.push(RoyalLibrary.sSIR({sirAddress: founders[idx], queene: 0}));
    proxyRegistry = _proxyRegistry;
  }

  /************************** ^CONSTRUCTOR REGION *************************************************** */

  /**
   * @notice The IPFS URI and contract hash.
   */
  function setIpfsContractURIHash(
    string calldata _providerUri,
    string calldata _contractHash
  ) external onlyOwnerOrDeveloperOrDAO onlyOnImplementationOrDAO {
    _ipfsProvider = _providerUri;
    _ipfsContractURIHash = _contractHash;
  }

  /**
   * @notice The IPFS URI of contract-level metadata.
   */
  function contractURI() public view override returns (string memory) {
    return string(abi.encodePacked(_ipfsProvider, _ipfsContractURIHash));
  }

  /**
   * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    override(ERC721, IERC721)
    returns (bool)
  {
    // Whitelist OpenSea proxy contract for easy trading.
    if (proxyRegistry.proxies(owner) == operator) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
  }

  /**
   * @notice Mint QueenE to the minter, along with a possible Sir reward
   * QueenE and a museum art.
   *Sir reward QueenEs are minted on 10th mint whenever there is a Sir
   * with no reward. It mint's only one QueenE reward for each Sir
   * Tokens 20, 40, 60 and 80 are minted for the founders with sir title
   * Except when there is a new sir with pending reward, every 10th QueenE is
   *minted for the museum for the first 1820 token (~5 years)
   * @dev Call _mintTo with the minter address.
   */
  function mint() public override onlyMinter returns (uint256) {
    if (_currentAuctionQueenE % 10 == 0 && _currentAuctionQueenE <= 1820) {
      address sirAddress = _getSirWithPendingAward(_currentAuctionQueenE);
      if (
        sirAddress != address(0) &&
        //send to founders sirs intercalated with museum and to sir after 90 if there is any
        (_currentAuctionQueenE == 20 ||
          _currentAuctionQueenE == 40 ||
          _currentAuctionQueenE == 60 ||
          _currentAuctionQueenE == 80 ||
          _currentAuctionQueenE > 90)
      ) {
        uint256 sirQueenE = _mintTo(sirAddress, _currentAuctionQueenE++, true);
        sirs[getSirIdx(sirAddress)].queene = _currentAuctionQueenE;

        emit SirAwarded(sirQueenE, sirAddress);
      } else {
        //mint to the vault
        uint256 museumQueenE = _mintTo(
          queenPalace.royalMuseum(),
          _currentAuctionQueenE++,
          false
        );

        emit MuseumAwarded(museumQueenE, queenPalace.royalMuseum());
      }
    }

    return _mintTo(queenPalace.minter(), _currentAuctionQueenE++, false);
  }

  /**
   * @notice Return QueenE from Id
   */
  function getQueenE(uint256 _queeneId)
    public
    view
    returns (RoyalLibrary.sQUEEN memory)
  {
    return queenes[_queeneId];
  }

  /**
   * @notice Burn a QueenE.
   */
  function burn(uint256 queeneId) public override onlyMinter {
    _burn(queeneId);
    emit QueenEBurned(queeneId);
  }

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    return
      queenPalace.QueenLab().constructTokenUri(queenes[tokenId], contractURI());
  }

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function setFinalArtHash(uint256 tokenId, string calldata _finalArtHash)
    external
    onlyOwner
  {
    require(_exists(tokenId), "QueenE::invalid id");
    require(
      //queenes[tokenId].finalArt.stringEquals(""),
      keccak256(abi.encodePacked(queenes[tokenId].finalArt)) ==
        keccak256(abi.encodePacked("")),
      "QueenE::Art set"
    );
    queenes[tokenId].finalArt = _finalArtHash;

    emit FinalArtSet(tokenId, _finalArtHash);
  }

  /**
   * @notice Lock the minter.
   * @dev This cannot be reversed and is only callable by the owner when not locked.
   */
  function lockMinter()
    external
    override
    onlyOwnerOrChiefDeveloper
    whenMinterNotLocked
  {
    isMinterLocked = true;

    emit MinterLocked();
  }

  /**
   * @notice Lock the QueenE Trait Storage contract.
   * @dev This cannot be reversed and is only callable by the owner when not locked.
   */
  function lockQueenTraitStorage()
    external
    override
    onlyOwnerOrChiefDeveloper
    whenTraitStorageNotLocked
  {
    isTraitStorageLocked = true;

    emit StorageLocked();
  }

  /**
   * @notice Lock the Queen Lab Contract.
   * @dev This cannot be reversed and is only callable by the owner when not locked.
   */
  function lockQueenLab()
    external
    override
    onlyOwnerOrChiefDeveloper
    whenLabNotLocked
  {
    isLabLocked = true;

    emit LabLocked();
  }

  /**
   * @notice Mint a QueenE with `queeneId` to the provided `to` address.
   */
  function _mintTo(
    address _to,
    uint256 _queeneId,
    bool isSirAward
  ) internal returns (uint256) {
    RoyalLibrary.sQUEEN memory queene = queenPalace.QueenLab().generateQueen(
      _queeneId,
      isSirAward
    );

    queenes[_queeneId].queeneId = queene.queeneId;
    queenes[_queeneId].queenesGallery = queene.queenesGallery;
    queenes[_queeneId].sirAward = queene.sirAward;

    for (uint256 idx = 0; idx < queene.dna.length; idx++) {
      queenes[_queeneId].dna.push(queene.dna[idx]);
    }

    queenes[_queeneId].description = queene.description;
    dnaMapping[uint256(keccak256(abi.encode(queenes[_queeneId].dna)))] = true;
    queeneRarityMap[_queeneId] = queenPalace.QueenLab().getQueenRarity(
      queene.dna
    );
    _mint(owner(), _to, _queeneId);

    return _queeneId;
  }

  /**
   * @dev Adjusts votes when tokens are transferred.
   *
   * Emits a {Votes-DelegateVotesChanged} event.
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    super._afterTokenTransfer(from, to, tokenId);
    //first lets take the seat from the old owner, if necessary
    if (!_takeParliamentSeat(from, tokenId)) {
      revert("QueenE::error taking seat");
    }

    //now lets give a seat to the new owner, if he deserves it
    if (!_giveParliamentSeat(to, tokenId)) {
      revert("QueenE::error giving seat");
    }

    if (ownerOfQueenEs[from].contains(tokenId))
      ownerOfQueenEs[from].remove(tokenId);

    if (!ownerOfQueenEs[to].contains(tokenId)) ownerOfQueenEs[to].add(tokenId);
  }

  /**
   * @dev nominate a subject to the sir title.
   *
   * Emits a {ChangedLordVoteMultiplier} event.
   */
  function setLordMultiplier(uint256 _multiplier)
    external
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    require(_multiplier >= 1, "QueenE::Invalid value");

    lordMultiplier = _multiplier;
    emit ChangedLordVoteMultiplier(_multiplier);
  }

  /**
   * @dev nominate a subject to the sir title.
   *
   * Emits a {NominatedForHouseOfLord} or {NominatedForHouseOfCommons} event.
   * Emits a {BannedFromHousesRejection} event if subject was banned.
   */
  function nominateSir(address _sir)
    external
    override
    onlySirOrDAO
    onlyOnImplementationOrDAO
    returns (bool)
  {
    require(_sir != address(0), "QueenE::Invalid address(0)");
    require(!houseOfBanned.contains(_sir), "QueenE::Banned");
    require(!IsSir(_sir), "QueenE::Already Sir");

    sirs.push(RoyalLibrary.sSIR({sirAddress: _sir, queene: 0}));
    emit SirNominated(_sir);

    return true;
  }

  /**
   *  Return house seats depending on seat type
   *
   * 0 - Sum of Lord and Common seats
   * 1 - Lord Seats
   * 2 - Common Seats
   * 3 - Banned from Seats
   *
   */
  function getHouseSeats(uint8 _seatType)
    external
    view
    override
    returns (uint256)
  {
    return
      ((_seatType == 0 || _seatType == 1) ? houseOfLords.length() : 0) +
      ((_seatType == 0 || _seatType == 2) ? houseOfCommons.length() : 0) +
      ((_seatType == 0 || _seatType == 3) ? houseOfBanned.length() : 0);
  }

  /**
   *  Return house seat for given address
   *
   * 1 - House of Lords
   * 2 - House of Commons
   * 3 - House of Banned
   * 0 - No House
   *
   */
  function getHouseSeat(address addr) external view override returns (uint256) {
    if (houseOfBanned.contains(addr)) return 3;
    else if (houseOfLords.contains(addr)) return 1;
    else if (houseOfCommons.contains(addr)) return 2;
    else return 0;
  }

  /**
   *  Return if given address have Sir Title
   *
   */
  function IsSir(address _address)
    public
    view
    override(IQueenE, QueenParliament)
    returns (bool)
  {
    return super.IsSir(_address);
  }

  /**
   * @dev return if given QueenE was a reward.
   *
   */
  function isSirReward(uint256 queeneId) public view override returns (bool) {
    return queenes[queeneId].sirAward == 1;
  }

  /**
   * @dev return if given QueenE belongs to the museum.
   *
   */
  function isMuseum(uint256 queeneId) public view override returns (bool) {
    return ownerOf(queeneId) == queenPalace.royalMuseum();
  }

  /**
   * @dev return if dna was already used
   *
   */
  function dnaMapped(uint256 dnaHash) external view override returns (bool) {
    return dnaMapping[dnaHash];
  }

  function isHouseOfLordsFull() external view override returns (bool) {
    return houseOfLordsFull;
  }
}
