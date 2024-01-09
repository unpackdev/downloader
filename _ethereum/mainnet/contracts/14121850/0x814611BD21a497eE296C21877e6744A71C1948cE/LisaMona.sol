pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./ERC1155Holder.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MonaTokens.sol";
import "./MonaHybrids.sol";
import "./Utils.sol";
import "./console.sol";

contract LisaMona is Ownable, ERC1155Holder, Utils {

  using Counters for Counters.Counter;

  /***************************************************************************
   * Events
   ***************************************************************************/
   event MintArtist(
     uint id
   );

  event StartArt(
    uint indexed artistId,
    uint id,
    uint creationReadyAt
  );

  event StartHybrid(
    uint indexed artistId,
    uint id,
    uint indexed contentId,
    uint indexed styleId,
    uint creationReadyAt
  );

  event MintArtistCreation(
    uint indexed artistId,
    uint id,
    bool isHybrid
  );

  event ParametersChange();

  event Donation(address donator, uint value);

  /***************************************************************************
   * Structs
   ***************************************************************************/
  struct ArtistStatus {
    bool isHybrid;
    uint48 creationReadyAt; // Time that the creation will be ready, or 0 if not working
    uint256 creationId; // ID of artwork or hybrid started
  }

  struct ArtistMintCosts {
    uint16 tierSize;
    uint256 perTierIncreaseEth;
    uint256 baseEth;
    uint256 maxEth;
  }

  struct StartCosts {
    uint256 artEth;
    uint256 hybridEth;
  }

  struct CreationTimes {
    uint32 artDuration; // How long to create art
    uint32 hybridDuration; // How long to create a Hybrid
  }

  struct MintSupply {
    uint32 maxArtists;
    uint32 maxArts;
    uint32 maxHybrids;
  }

  /***************************************************************************
   * State
   ***************************************************************************/
  ArtistMintCosts public artistMintCosts = ArtistMintCosts({
    tierSize: 100,
    perTierIncreaseEth: 0.01 ether,
    baseEth: 0.03 ether,
    maxEth: 10 ether
  });

  StartCosts public startCosts = StartCosts({
    artEth: 0.03 ether,
    hybridEth: 0.01 ether
  });

  CreationTimes public creationTimes = CreationTimes({
    artDuration: 3 hours,
    hybridDuration: 8 hours
  });

  MintSupply public mintSupply = MintSupply({
    maxArtists: 4761,
    maxArts: 10069,
    maxHybrids: 1000000
  });

  Counters.Counter public artistsCount;
  Counters.Counter public artsCount;
  Counters.Counter public hybridsCount;

  // Mapping of artist ID => ArtistStatus
  mapping(uint256 => ArtistStatus) public artistStatus;

  mapping(uint256 => bool) private artStarted;

  MonaTokens private monaTokens;
  MonaHybrids private monaHybrids;

  constructor(address _monaTokensAddress, address _monaHybridsAddress) {
    monaTokens = MonaTokens(_monaTokensAddress);
    monaHybrids = MonaHybrids(_monaHybridsAddress);
    emit ParametersChange();
  }

  function setArtistMintCosts(
    uint16 tierSize,
    uint256 perTierIncreaseEth,
    uint256 baseEth,
    uint256 maxEth
  ) public onlyOwner {
    artistMintCosts.tierSize = tierSize;
    artistMintCosts.perTierIncreaseEth = perTierIncreaseEth;
    artistMintCosts.baseEth = baseEth;
    artistMintCosts.maxEth = maxEth;

    emit ParametersChange();
  }

  function setStartCosts(uint256 artEth, uint256 hybridEth) public onlyOwner {
    startCosts.artEth = artEth;
    startCosts.hybridEth = hybridEth;

    emit ParametersChange();
  }

  function setCreationTimes(uint32 _art, uint32 _hybrid) public onlyOwner {
    creationTimes.artDuration = _art;
    creationTimes.hybridDuration = _hybrid;

    emit ParametersChange();
  }

  function setMintSupply(uint32 _maxArtists, uint32 _maxArts, uint32 _maxHybrids) public onlyOwner {
    mintSupply.maxArtists = _maxArtists;
    mintSupply.maxArts = _maxArts;
    mintSupply.maxHybrids = _maxHybrids;

    emit ParametersChange();
  }

  function mintArtistWithEth() payable public returns (uint) {
    require(artistsCount.current() < mintSupply.maxArtists, "No more artists to mint");
    require(msg.value >= getPriceEthMintArtist(), "Not enough ETH");

    uint availableId = getRandom(mintSupply.maxArtists);
    while (monaTokens.isMinted(getArtistId(availableId))) {
      availableId = (availableId + 1) % mintSupply.maxArtists;
    }

    uint id = monaTokens.mintArtist(msg.sender, getArtistId(availableId));
    artistStatus[id] = ArtistStatus(false, 0, 0);
    artistsCount.increment();

    // This event is used by the dapp to get the ID of the minted artist
    // after running the transaction
    emit MintArtist(id);

    return id;
  }

  function startArtWithEth(uint _artistId) payable public {
    require(artsCount.current() < mintSupply.maxArts, "No more art to mint");
    require(monaTokens.tokenOwner(_artistId) == msg.sender, "You do not own this artist");
    _requireArtistIdle(_artistId);
    require(msg.value >= getPriceEthStartArt(), "Not enough ETH");

    uint availableId = getRandom(mintSupply.maxArts);
    while (artStarted[getArtId(availableId)]) {
      availableId = (availableId + 1) % mintSupply.maxArts;
    }

    uint artId = getArtId(availableId);
    artStarted[artId] = true;
    uint48 creationReadyAt = uint48(block.timestamp) + creationTimes.artDuration;
    artistStatus[_artistId].creationReadyAt = creationReadyAt;
    artistStatus[_artistId].creationId = artId;
    artistStatus[_artistId].isHybrid = false;
    artsCount.increment();

    emit StartArt(_artistId, artId, creationReadyAt);
  }

  function startHybridWithEth(uint _artistId, uint _contentId, uint _styleId) payable public returns (uint) {
    require(hybridsCount.current() < mintSupply.maxHybrids, "No more hybrids to mint");
    require(monaTokens.tokenOwner(_artistId) == msg.sender, "You do not own this artist");
    require(monaTokens.isMinted(_contentId) || monaHybrids.isMinted(_contentId), "Content art is invalid");
    require(monaTokens.tokenOwner(_styleId) == msg.sender || monaHybrids.tokenOwner(_styleId) == msg.sender, "Must be owner of style art");
    _requireArtistIdle(_artistId);
    uint hybridId = getHybridId(_contentId, _styleId);
    require(!artStarted[hybridId], "Hybrid combination already exists");
    require(msg.value >= getPriceEthStartHybrid(), "Not enough ETH");

    artStarted[hybridId] = true;
    uint48 creationReadyAt = uint48(block.timestamp) + creationTimes.hybridDuration;
    artistStatus[_artistId].creationReadyAt = creationReadyAt;
    artistStatus[_artistId].creationId = hybridId;
    artistStatus[_artistId].isHybrid = true;
    hybridsCount.increment();

    emit StartHybrid(_artistId, hybridId, _contentId, _styleId, creationReadyAt);

    return hybridId;
  }

  /**
   * Mint the hybrid being worked on by the specified artist
   */
  function mintArtistCreation(uint _artistId) public returns (uint) {
    require(monaTokens.tokenOwner(_artistId) == msg.sender, "You do not own this artist");

    ArtistStatus memory status = artistStatus[_artistId];

    require(status.creationReadyAt > 0, "Artist is not working");
    // block.timestamp is always going to lag "now" by a certain amount of time due to
    // the time it takes to mine a block, so add on a bit of buffer to it. This prevents
    // situation where the client thinks a mint is ready but the contract still doesn't
    // until the next block.
    require((block.timestamp + 1 minutes) >= status.creationReadyAt, "Creation not ready");

    uint id;
    bool isHybrid = status.isHybrid;
    if (isHybrid) {
      id = monaHybrids.mintHybrid(msg.sender, status.creationId);
    } else {
      id = monaTokens.mintArt(msg.sender, status.creationId);
    }

    // Reset artist state back to "idle"
    artistStatus[_artistId].isHybrid = false;
    artistStatus[_artistId].creationReadyAt = 0;
    artistStatus[_artistId].creationId = 0;

    emit MintArtistCreation(_artistId, id, isHybrid);

    return id;
  }

  function withdraw() onlyOwner external {
    require(payable(msg.sender).send(address(this).balance));
  }

  receive() external payable {
    emit Donation({donator: msg.sender, value: msg.value});
  }

  function kill() onlyOwner external {
    selfdestruct(payable(owner()));
  }

  function getPriceEthMintArtist() view public returns (uint) {
    uint tier = _getTier(artistsCount.current(), artistMintCosts.tierSize);

    return min(
      artistMintCosts.baseEth + tier * artistMintCosts.perTierIncreaseEth,
      artistMintCosts.maxEth
    );
  }

  function getPriceEthStartArt() view public returns (uint) {
    return startCosts.artEth;
  }

  function getPriceEthStartHybrid() view public returns (uint) {
    return startCosts.hybridEth;
  }

  // Tier starts at 0
  function _getTier(uint count, uint tierSize) private pure returns (uint) {
    if (tierSize == 0) {
      return 0;
    }

    return count / tierSize;
  }

  function _requireArtistIdle(uint _artistId) private view {
    require(artistStatus[_artistId].creationReadyAt == 0, "Artist is busy");
  }
}