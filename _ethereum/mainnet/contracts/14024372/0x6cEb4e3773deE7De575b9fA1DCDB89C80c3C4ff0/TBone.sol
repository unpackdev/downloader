// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./ERC721Enumerable.sol";

import "./ERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract TBone is ERC20Upgradeable, AccessControlUpgradeable {
  /// Minter role
  bytes32 public constant ROLE_MINTER = keccak256("MINTER");

  /// Unleashed role
  bytes32 public constant ROLE_UNLEASHED = keccak256("UNLEASHED");

  /// The start date of TBONEs creation
  uint256 public start;

  /// The ratio that TBONEs are generated per day
  uint256 public ratioPerDay;

  /// The base cost of a name change in TBONEs
  uint256 public nameChangeBaseCost;

  /// Number of seconds in a day
  uint256 public constant DAY_IN_SECONDS = 60 * 60 * 24;

  // Thug Pugs will yield TBONE during 10 years (in seconds)
  uint256 public constant YIELD_PERIOD = 60 * 60 * 24 * 36525 / 10;

  /// The ratio that genesis pugs generate TBONEs over unleashed pugs
  uint256 public genesisRatio;

  /// Genesis address
  address public genesisPugs;

  /// Unleashed address
  address public unleashedPugs;

  /// Holds the lastest timestamp that a genesis pug claimed tbones
  mapping(uint256 => uint256) public genesisClaims;

  /// Holds the lastest timestamp that an unleashed pug claimed tbones
  mapping(uint256 => uint256) public unleashedClaims;

  /// holds the number of times an unleashed pug has changed name
  mapping(uint256 => uint256) public unleashedNameChangeTracker;

  /// holds the number of times a genesis pug has changed name
  mapping(uint256 => uint256) public genesisNameChangeTracker;

  /// holds the names of all unleashed pugs
  mapping(uint256 => string) public unleashedNames;

  /// holds the names of all genesis pugs
  mapping(uint256 => string) public genesisNames;

  /// holds the different reserved names for uniqueness validations
  mapping(string => bool) public nameReserve;

  /// emitted when someone claims tbones
  event TokenClaim(address indexed owner, uint256 amount);

  /// emitted when the name of a pug is changed
  event NameChange(uint256 tokenId, string name, address indexed collection, uint256 cost);

  function initialize(uint256 _start, uint256 _ratioPerDay, uint256 _genesisRatio, address _owner) initializer public {
    __ERC20_init("T-Bone", "TBONE");
    start = _start;
    ratioPerDay = _ratioPerDay;
    genesisRatio = _genesisRatio;
    nameChangeBaseCost = 10 ether;

    _setupRole(DEFAULT_ADMIN_ROLE, _owner);
  }

  function addMinter(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setupRole(ROLE_MINTER, _minter);
  }

  function setUnleashed(address _unleashedPugs) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(unleashedPugs == address(0x0), "Unleashed already set");

    unleashedPugs = _unleashedPugs;
  }

  function setGenesis(address _genesisPugs) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(genesisPugs == address(0x0), "Genesis already set");

    genesisPugs = _genesisPugs;
  }

  function isMinter(address _minter) public view returns (bool) {
    return hasRole(ROLE_MINTER, _minter);
  }

  function isAdmin(address _admin) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, _admin);
  }

  function mint(address _to, uint256 _amount) public onlyRole(ROLE_MINTER) {
    _mint(_to, _amount);
  }

  function burn(address _from, uint256 _amount) public onlyRole(ROLE_MINTER) {
    _burn(_from, _amount);
  }

  function claimTokens() public {
    require(block.timestamp > start, "tbone generation hasn't started yet");

    uint256 owedTokens = 0;

    // calculate owedTokens for genesis pugs
    for(uint256 i = 0; i < IERC721(genesisPugs).balanceOf(msg.sender); i++ ) {
      uint256 token = IERC721Enumerable(genesisPugs).tokenOfOwnerByIndex(msg.sender, i);
      owedTokens += calculateTokensSinceLastClaim(token, block.timestamp, true);
      genesisClaims[token] = block.timestamp;
    }

    // calculate owedTokens for unleashed pugs
    if (unleashedPugs != address(0x0)) {
      for(uint256 i = 0; i < IERC721(unleashedPugs).balanceOf(msg.sender); i++ ) {
        uint256 token = IERC721Enumerable(unleashedPugs).tokenOfOwnerByIndex(msg.sender, i);
        require(unleashedClaims[token] > 0, "Unleashed was not initialized");

        owedTokens += calculateTokensSinceLastClaim(token, block.timestamp, false);
        unleashedClaims[token] = block.timestamp;
      }
    }

    require(owedTokens > 0, "wallet doesn't have any TBONEs to claim");

    _mint(msg.sender, owedTokens);

    emit TokenClaim(msg.sender, owedTokens);
  }

  function calculateAmountAvailableToBeClaimed(address _owner, uint256 timestamp) public view returns (uint256) {
    uint256 owedTokens = 0;

    // calculate owedTokens for genesis pugs
    for(uint256 i = 0; i < IERC721(genesisPugs).balanceOf(_owner); i++ ) {
      uint256 token = IERC721Enumerable(genesisPugs).tokenOfOwnerByIndex(_owner, i);
      owedTokens += calculateTokensSinceLastClaim(token, timestamp, true);
    }

    // calculate owedTokens for unleashed pugs
    if (unleashedPugs != address(0x0)) {
      for(uint256 i = 0; i < IERC721(unleashedPugs).balanceOf(_owner); i++ ) {
        uint256 token = IERC721Enumerable(unleashedPugs).tokenOfOwnerByIndex(_owner, i);
        require(unleashedClaims[token] > 0, "Unleashed was not initialized");

        owedTokens += calculateTokensSinceLastClaim(token, timestamp, false);
      }
    }

    return owedTokens;
  }

  function calculateTokensSinceLastClaim(uint256 _token, uint256 _date, bool _genesis) public view returns (uint256) {
    uint256 claim = _genesis ? genesisClaims[_token] : unleashedClaims[_token];
    uint256 lastClaimedDate = claim == 0 ? start : claim;
    // yielding happens only during yield period
    uint256 date = _date > (start + YIELD_PERIOD) ? (start + YIELD_PERIOD) : _date;

    uint256 tokens = ratioPerDay * (date - lastClaimedDate) / DAY_IN_SECONDS;

    return _genesis ? tokens * genesisRatio : tokens;
  }

  function setUnleashedStartDate(uint256 _token, uint256 _date) public onlyRole(ROLE_UNLEASHED) {
    unleashedClaims[_token] = _date;
  }

  function setName(uint256 _tokenId, string memory _newName, bool _genesis) public returns (bool) {
    require(bytes(_newName).length > 0, "Name can't be empty");
    require(nameReserve[_newName] != true, "Name is already taken");

    return _setName(_tokenId, _newName, _genesis ? genesisPugs : unleashedPugs);
  }

  function _setName(uint256 _tokenId, string memory _newName, address _collection) private returns (bool) {
    require(IERC721Enumerable(_collection).ownerOf(_tokenId) == msg.sender, "Sender is not the owner of the pug");

    nameReserve[_newName] = true;
    uint256 cost;

    if (_collection == genesisPugs) {
      cost = nameChangeBaseCost * 2 ** genesisNameChangeTracker[_tokenId];
      genesisNameChangeTracker[_tokenId] += 1;

      if (bytes(genesisNames[_tokenId]).length > 0) {
        nameReserve[genesisNames[_tokenId]] = false;
      }

      genesisNames[_tokenId] = _newName;
    } else {
      cost = nameChangeBaseCost * 2 ** unleashedNameChangeTracker[_tokenId];
      unleashedNameChangeTracker[_tokenId] += 1;

      if (bytes(unleashedNames[_tokenId]).length > 0) {
        nameReserve[unleashedNames[_tokenId]] = false;
      }

      unleashedNames[_tokenId] = _newName;
    }

    emit NameChange(_tokenId, _newName, _collection, cost);

    require(balanceOf(msg.sender) >= cost, "Insufficient funds for name change");
    _burn(msg.sender, cost);

    return true;
  }

  function costOfChange(uint256 _tokenId, bool _genesis) public view returns (uint256) {
    uint256 cost;

    if (_genesis) {
      cost = nameChangeBaseCost * 2 ** genesisNameChangeTracker[_tokenId];
    } else {
      cost = nameChangeBaseCost * 2 ** unleashedNameChangeTracker[_tokenId];
    }

    return cost;
  }

  function nameOfToken(uint256 _tokenId, bool _genesis) public view returns (string memory) {
    return _genesis ? genesisNames[_tokenId] : unleashedNames[_tokenId];
  }
}
