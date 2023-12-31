// SPDX-License-Identifier: AGPL-3.0-or-later
/*
01000001 01101010 01101001 01101111 01101110  01001100 01100001 01100010 01110011 00110010 00110000 00110010 00110011
 ██░ ██ ▓█████  ██▀███   ▒█████  ▓█████   ██████     ▒█████    █████▒               
▓██░ ██▒▓█   ▀ ▓██ ▒ ██▒▒██▒  ██▒▓█   ▀ ▒██    ▒    ▒██▒  ██▒▓██   ▒                
▒██▀▀██░▒███   ▓██ ░▄█ ▒▒██░  ██▒▒███   ░ ▓██▄      ▒██░  ██▒▒████ ░                
░▓█ ░██ ▒▓█  ▄ ▒██▀▀█▄  ▒██   ██░▒▓█  ▄   ▒   ██▒   ▒██   ██░░▓█▒  ░                
░▓█▒░██▓░▒████▒░██▓ ▒██▒░ ████▓▒░░▒████▒▒██████▒▒   ░ ████▓▒░░▒█░                   
 ▒ ░░▒░▒░░ ▒░ ░░ ▒▓ ░▒▓░░ ▒░▒░▒░ ░░ ▒░ ░▒ ▒▓▒ ▒ ░   ░ ▒░▒░▒░  ▒ ░                   
 ▒ ░▒░ ░ ░ ░  ░  ░▒ ░ ▒░  ░ ▒ ▒░  ░ ░  ░░ ░▒  ░ ░     ░ ▒ ▒░  ░                     
 ░  ░░ ░   ░     ░░   ░ ░ ░ ░ ▒     ░   ░  ░  ░     ░ ░ ░ ▒   ░ ░                   
 ░  ░  ░   ░  ░   ░         ░ ░     ░  ░      ░         ░ ░                         
                                                                                    
  ██████  ▄▄▄       ███▄    █  ▄████▄  ▄▄▄█████▓ █    ██  ▄▄▄       ██▀███ ▓██   ██▓
▒██    ▒ ▒████▄     ██ ▀█   █ ▒██▀ ▀█  ▓  ██▒ ▓▒ ██  ▓██▒▒████▄    ▓██ ▒ ██▒▒██  ██▒
░ ▓██▄   ▒██  ▀█▄  ▓██  ▀█ ██▒▒▓█    ▄ ▒ ▓██░ ▒░▓██  ▒██░▒██  ▀█▄  ▓██ ░▄█ ▒ ▒██ ██░
  ▒   ██▒░██▄▄▄▄██ ▓██▒  ▐▌██▒▒▓▓▄ ▄██▒░ ▓██▓ ░ ▓▓█  ░██░░██▄▄▄▄██ ▒██▀▀█▄   ░ ▐██▓░
▒██████▒▒ ▓█   ▓██▒▒██░   ▓██░▒ ▓███▀ ░  ▒██▒ ░ ▒▒█████▓  ▓█   ▓██▒░██▓ ▒██▒ ░ ██▒▓░
▒ ▒▓▒ ▒ ░ ▒▒   ▓▒█░░ ▒░   ▒ ▒ ░ ░▒ ▒  ░  ▒ ░░   ░▒▓▒ ▒ ▒  ▒▒   ▓▒█░░ ▒▓ ░▒▓░  ██▒▒▒ 
░ ░▒  ░ ░  ▒   ▒▒ ░░ ░░   ░ ▒░  ░  ▒       ░    ░░▒░ ░ ░   ▒   ▒▒ ░  ░▒ ░ ▒░▓██ ░▒░ 
░  ░  ░    ░   ▒      ░   ░ ░ ░          ░       ░░░ ░ ░   ░   ▒     ░░   ░ ▒ ▒ ░░  
      ░        ░  ░         ░ ░ ░                  ░           ░  ░   ░     ░ ░     
                              ░                                             ░ ░     
01000001 01101010 01101001 01101111 01101110 00100000 01000011 01101111 01110010 01110000 01101111 01110010 01100001 01110100 01101001 01101111 01101110                                                       
*/
pragma solidity >=0.8.19 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";

import "./Strings.sol";

import "./AggregatorV3Interface.sol";
import "./HOSWinnersSUB.sol";

contract HOSNftToken is HOSWinnersSUB, ERC721AQueryable {
  using Strings for uint256;

  AggregatorV3Interface internal priceFeed;

  // ********** VARIABLES ********** //

  // Registration is closed for the current season
  bool public lockedSeason = false;

  // Final snapshot for the season
  bool public seasonEnded = false;

  uint256 public entryFeeInUsd = 50; // In USD

  string public uriPrefix = "";
  string public uriSuffix = ".json";

  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public lockedSupply = false;

  // Storing keys for offical URIs
  string[] public keyRecords;
  uint256 public keyRecordsLength = 0;

  // Mapping from season number to balance
  mapping(uint => uint) public seasonBalances;

  // Mapping to record the season of each holder, by address and all of Holders during season
  mapping(address => uint256) public seasonOfHolder;

  // Mapping to record the snapshot of holders for each season
  mapping(uint256 => address[]) public _seasonSnapshot;

  // Mapping to record if a holder is active for a season, with the tokenIds
  mapping(uint256 => mapping(address => uint256[])) public _activeHolders;

  // Mapping to record if a holder is active for a season, with the tokenIds
  mapping(uint256 => mapping(address => uint256[])) public _finalHolders;

  // Mapping to record the snapshot of holders for each season
  mapping(uint256 => address[]) public _activeHoldersSeason;

  // Mapping to record the snapshot of holders at the end of the season
  mapping(uint256 => address[]) public _finalHoldersSeason;

  // Mapping to record the snapshot of holders for each season
  mapping(uint256 => string) public seasonRecordsURI;

  // Mapping to set of official URIs for contract confirmation
  mapping(string => string) public officialURIs;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    address _priceFeed
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    priceFeed = AggregatorV3Interface(_priceFeed);
  }

  // ********** EVENTS ********** //
  event Received(address, uint);
  event Minted(address indexed to, uint256 amount, uint256 totalSupply);
  event MintedForAddress(
    address indexed to,
    uint256 amount,
    uint256 totalSupply
  );
  event MaxSupplyChanged(uint256 oldMaxSupply, uint256 newMaxSupply);
  event URIPrefixChanged(string oldPrefix, string newPrefix);
  event URISuffixChanged(string oldSuffix, string newSuffix);
  event PausedStateSet(bool isPaused);
  event LockStateSet(bool isLocked);
  event SeasonEndStateUpdate(bool state);
  event SeasonChanged(uint256 oldSeason, uint256 newSeason);

  event SeasonLockedStateSet(uint256 season, bool isLocked);
  event PriceFeedChanged(address oldPriceFeed, address newPriceFeed);
  event SeasonEntryFeeChanged(uint256 oldFee, uint256 newFee);
  event SeasonFeePaid(address payer, uint256 season, uint256 fee);

  event AddPlayerToSeason(address player, uint256 season);
  event SetActiveSeasonSnapshot(uint256 season);
  event SeasonEndActiveHoldersSnapshot(uint256 season);
  event Withdraw();

  event SetOwnerCommission(uint percentage);

  event SetRecordSeasonURI(uint season, string uri);

  event PlayerRemovedFromSeason(address player, uint season);
  event PlayerAddedToSeason(address player, uint season);

  // ********** RECEIVE ********** //
  receive() external payable {
    emit Received(msg.sender, msg.value);

    // Update the balance for the current season
    seasonBalances[currentSeason] += msg.value;
  }

  // ********** MODIFIERS ********** //
  modifier mintCompliance(uint256 _mintAmount) {
    require(
      _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
      "Invalid amount"
    );
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    uint256 mintPriceInEth = calculateEntryFeeInEth();
    require(msg.value >= _mintAmount * mintPriceInEth, "Deficient funds");
    _;
  }

  // ********** SERVICES ********** //
  function mint(
    uint256 _mintAmount
  )
    public
    payable
    mintCompliance(_mintAmount)
    mintPriceCompliance(_mintAmount)
  {
    require(!paused, "Mint is paused");
    require(!(isPlayerInSeason(_msgSender()) && lockedSeason), "locked");

    uint256 adjust = lockedSeason ? 1 : 0;
    uint256 actualSeason = currentSeason + adjust;

    _safeMint(_msgSender(), _mintAmount);
    seasonOfHolder[_msgSender()] = actualSeason;

    bool found = false;
    for (uint i = 0; i < _seasonSnapshot[actualSeason].length; i++) {
      if (_seasonSnapshot[actualSeason][i] == _msgSender()) {
        found = true;
        break;
      }
    }

    if (!found) {
      _seasonSnapshot[actualSeason].push(_msgSender());
    }

    seasonBalances[actualSeason] += msg.value;
    emit Minted(_msgSender(), _mintAmount, totalSupply());
  }

  function mintForAddress(
    uint256 _mintAmount,
    address _receiver
  ) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
    emit MintedForAddress(_receiver, _mintAmount, totalSupply());
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(
    uint256 _tokenId
  ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    require(_exists(_tokenId), "No token");

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)
        )
        : "";
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    require(!lockedSupply, "Supply locked");
    maxSupply = _maxSupply;
    emit MaxSupplyChanged(totalSupply(), _maxSupply);
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
    emit URIPrefixChanged(uriPrefix, _uriPrefix);
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
    emit URISuffixChanged(uriSuffix, _uriSuffix);
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
    emit PausedStateSet(paused);
  }

  function setLocked(bool _lock) public onlyOwner {
    require(!lockedSupply, "Supply locked");
    lockedSupply = _lock;
    emit LockStateSet(lockedSupply);
  }

  // ********** SEASON ********** //
  function setCurrentSeason(uint256 _season) public onlyOwner {
    require(_season > currentSeason, "!gt season");
    currentSeason = _season;
    lockSeason(false);
    setSeasonEnd(false);
    emit SeasonChanged(currentSeason, _season);
  }

  // Season is locked when the snapshot is taken and no more players can join
  function lockSeason(bool _stateLocked) public onlyOwner {
    lockedSeason = _stateLocked;
    emit SeasonLockedStateSet(currentSeason, lockedSeason);
  }

  // Season ended when the final snapshot is taken, anyone holding Ticket(NFT) are the final participants
  function setSeasonEnd(bool _state) public onlyOwner {
    seasonEnded = _state;
    emit SeasonEndStateUpdate(seasonEnded);
  }

  // Determine if Player is in the current season through different states of a season and holding a Ticket(NFT)
  function isPlayerInSeason(address _player) public view returns (bool) {
    if (seasonEnded) {
      return
        seasonOfHolder[_player] == currentSeason &&
        _finalHolders[currentSeason][_player].length > 0 &&
        balanceOf(_player) > 0;
    }

    if (lockedSeason) {
      return
        seasonOfHolder[_player] == currentSeason &&
        _activeHolders[currentSeason][_player].length > 0 &&
        balanceOf(_player) > 0;
    }

    return seasonOfHolder[_player] == currentSeason && balanceOf(_player) > 0;
  }

  // Get the current season of a player
  function getPlayerSeason(address _player) public view returns (uint256) {
    return seasonOfHolder[_player];
  }

  // Get a list of participants for a season
  function getHoldersForSeason(
    uint256 _season
  ) public view returns (address[] memory) {
    return _seasonSnapshot[_season];
  }

  // Get a list of participants for a season post Snapshot
  function getActiveSeasonPlayers(
    uint256 _season
  ) public view returns (address[] memory) {
    return _activeHoldersSeason[_season];
  }

  // Get a final list of participants at the end of a season
  function getFinalSeasonPlayers(
    uint256 _season
  ) public view returns (address[] memory) {
    return _finalHoldersSeason[_season];
  }

  // Is player active in a season post snapshop
  function isActiveHolder(
    uint256 _season,
    address _holder
  ) public view returns (uint256[] memory) {
    return _activeHolders[_season][_holder];
  }

  // Is player active in a season at the end of the season
  function isFinalHolder(
    uint256 _season,
    address _holder
  ) public view returns (uint256[] memory) {
    return _finalHolders[_season][_holder];
  }

  // BAN or Griefing behaviour
  function removePlayerFromSeason(
    address _player,
    uint256 _season
  ) public onlyOwner {
    if (seasonEnded) {
      require(_finalHolders[_season][_player].length > 0, "Not in season");

      delete _finalHolders[_season][_player];
      seasonOfHolder[_player] = 0;
    } else if (lockedSeason) {
      require(_activeHolders[_season][_player].length > 0, "Not in season");

      delete _activeHolders[_season][_player];
      seasonOfHolder[_player] = 0;
    } else {
      require(_seasonSnapshot[_season].length > 0, "No players");
      seasonOfHolder[_player] = 0;
    }
    emit PlayerRemovedFromSeason(_player, _season);
  }

  // In case the ban or wrong behaviour was a mistake
  function addPlayerToSeason(
    address _player,
    uint256 _season
  ) public onlyOwner {
    if (seasonEnded) {
      require(_finalHolders[_season][_player].length == 0, "Player in season");

      require(balanceOf(_player) > 0, "Balance 0");

      _finalHolders[_season][_player] = this.tokensOfOwner(_player);
      seasonOfHolder[_player] = _season;
    } else if (lockedSeason) {
      require(_activeHolders[_season][_player].length == 0, "Player in season");
      require(balanceOf(_player) > 0, "Balance 0");

      _activeHolders[_season][_player] = this.tokensOfOwner(_player);
      seasonOfHolder[_player] = _season;
    } else {
      require(seasonOfHolder[_player] != _season, "Player in season");
      require(balanceOf(_player) > 0, "Balance 0");

      seasonOfHolder[_player] = _season;

      bool found = false;
      for (uint i = 0; i < _seasonSnapshot[_season].length; i++) {
        if (_seasonSnapshot[_season][i] == _msgSender()) {
          found = true;
          break;
        }
      }

      if (!found) {
        _seasonSnapshot[_season].push(_msgSender());
      }
    }
    emit PlayerAddedToSeason(_player, _season);
  }

  // One month or so, before season ends, we take a snapshot of the active Players for the season
  function setActiveSeasonSnapshot(uint256 _season) public onlyOwner {
    require(_season == currentSeason, "Wrong season");

    for (uint i = 0; i < _seasonSnapshot[_season].length; i++) {
      address holder = _seasonSnapshot[_season][i];
      uint256 balance = balanceOf(holder);

      if (balance > 0 && seasonOfHolder[holder] == _season) {
        _activeHolders[_season][holder] = this.tokensOfOwner(holder);
        _activeHoldersSeason[_season].push(holder);
      }
    }

    // We lock the season so no more players can join
    lockSeason(true);
    emit SetActiveSeasonSnapshot(_season);
  }

  // At the end of the season, we take a final snapshot of the active Players for the season
  function seasonEndActiveHoldersSnapshot(uint256 _season) public onlyOwner {
    require(_season == currentSeason, "Wrong season");

    for (uint i = 0; i < _activeHoldersSeason[_season].length; i++) {
      address holder = _activeHoldersSeason[_season][i];
      uint256 balance = balanceOf(holder);

      if (balance > 0 && seasonOfHolder[holder] == _season) {
        _finalHolders[_season][holder] = this.tokensOfOwner(holder);
        _finalHoldersSeason[_season].push(holder);
      }
    }

    // Season ended and winners are to be determined
    setSeasonEnd(true);
    emit SeasonEndActiveHoldersSnapshot(_season);
  }

  // Direct seasonal bance from all the direct minting or season fees
  function getBalanceForSeason(uint _season) public view returns (uint) {
    return seasonBalances[_season];
  }

  // ********** PAY SEASON ********** //
  function paySeasonFee() public payable {
    uint256 seasonFeeInEth = calculateEntryFeeInEth();

    require(lockedSeason == false, "Season locked");

    require(balanceOf(_msgSender()) >= 1, "0 NFT");

    require(
      seasonOfHolder[_msgSender()] != currentSeason,
      "Already paid season fee"
    );

    require(msg.value >= seasonFeeInEth, "Not enough Ether");

    seasonOfHolder[_msgSender()] = currentSeason;
    _seasonSnapshot[currentSeason].push(_msgSender());
    seasonBalances[currentSeason] += seasonFeeInEth;
    emit SeasonFeePaid(_msgSender(), currentSeason, seasonFeeInEth);
  }

  // ********** PRICE ********** //

  // Get the latest ETH/USD price from Chainlink
  function getLatestEthUsdPrice() public view returns (int) {
    (, int price, , uint timeStamp, ) = priceFeed.latestRoundData();

    // If the round is not complete yet, timestamp is 0
    require(timeStamp > 0, "ERR");
    return price;
  }

  // Set the ETH/USD price feed ADDRESS from Chainlink
  function setPriceFeed(address _newPriceFeed) public onlyOwner {
    require(_newPriceFeed != address(0), "Address !0");

    emit PriceFeedChanged(address(priceFeed), _newPriceFeed);
    priceFeed = AggregatorV3Interface(_newPriceFeed);
  }

  // Set the entry fee for a season in USD
  function setSeasonEntryFeeInUsd(uint256 _newEntryFeeInUsd) public onlyOwner {
    require(_newEntryFeeInUsd > 0, "Fee <= 0");
    emit SeasonEntryFeeChanged(entryFeeInUsd, _newEntryFeeInUsd);
    entryFeeInUsd = _newEntryFeeInUsd;
  }

  // Calculate the entry fee for a season in ETH
  function calculateEntryFeeInEth() public view returns (uint256) {
    int ethUsdPrice = getLatestEthUsdPrice();

    require(ethUsdPrice > 0, "Feed error");

    uint latestPriceWei = uint(uint(ethUsdPrice) / 1e8);

    return (entryFeeInUsd * 10 ** 18) / latestPriceWei;
  }

  // ********** COMMISSION ********** //
  // Set the owner commission percentage but no more than 30%
  function setOwnerCommission(uint _percentage) public onlyOwner {
    require(_percentage <= 30, "> 30");
    ownerCommission = _percentage;
    emit SetOwnerCommission(_percentage);
  }

  // ********** OVERRIDES ********** //
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  // Keeping a meta record of the seasons via IPFS when seasons are finished, so they remain pernament
  function recordSeasonURI(
    uint256 _season,
    string memory _uri
  ) public onlyOwner {
    seasonRecordsURI[_season] = _uri;
    emit SetRecordSeasonURI(_season, _uri);
  }

  // Offical URIs for contract confirmation
  function setContractOfficialURIs(
    string memory _key,
    string memory _uri
  ) public onlyOwner {
    if (
      keccak256(abi.encodePacked(officialURIs[_key])) ==
      keccak256(abi.encodePacked(""))
    ) {
      keyRecords.push(_key);
      keyRecordsLength += 1;
    }
    officialURIs[_key] = _uri;
  }
}
