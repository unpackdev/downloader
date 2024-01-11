//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*

Y2123 Land

y2123.com

*/

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";
import "./Counters.sol";
import "./Address.sol";
import "./ERC721A.sol";
import "./IOxygen.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract Clans {
  struct ClanStruct {
    uint256 clanId;
    uint256 updateClanTimestamp;
    bool isEntity;
  }

  mapping(address => ClanStruct) public clanStructs;
}

contract Land is ERC721A, Ownable, ReentrancyGuard {
  using Address for address;

  address public clansAddress;
  address public proxyRegistryAddress;
  IOxygen public oxgnToken;
  uint256 public MAX_SUPPLY = 400;
  string private baseURI;
  uint256 public mintPrice = 500 ether;
  bool public saleEnabled = true;
  bool public transferLogicEnabled = false;
  bool public openseaProxyEnabled = true;
  bool public upgradeSameColonyEnabled = true;

  event Stake(uint256 tokenId, address contractAddress, address owner, uint256 indexed landTokenId);
  event Unstake(uint256 tokenId, address contractAddress, address owner, uint256 indexed landTokenId);
  event StakeInternal(uint256 tokenId, address contractAddress, address owner, uint256 indexed landTokenId);
  event UnstakeInternal(uint256 tokenId, address contractAddress, address owner, uint256 indexed landTokenId);

  constructor(
    string memory uri,
    address _oxgnToken,
    address _clansAddress,
    address _proxyRegistryAddress
  ) ERC721A("Y2123.Land", "Y2123.Land") {
    baseURI = uri;
    setOxgnContract(_oxgnToken);
    setClansContract(_clansAddress);
    setProxyRegistry(_proxyRegistryAddress);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setOxgnContract(address _oxgnToken) public onlyOwner {
    oxgnToken = IOxygen(_oxgnToken);
  }

  function setClansContract(address _clansAddress) public onlyOwner {
    clansAddress = _clansAddress;
  }

  function setProxyRegistry(address _proxyRegistryAddress) public onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
    if (MAX_SUPPLY != newMaxSupply) {
      require(newMaxSupply > totalSupply(), "Value lower than total supply");
      MAX_SUPPLY = newMaxSupply;
    }
  }

  function setMintPrice(uint256 newPrice) external onlyOwner {
    mintPrice = newPrice;
  }

  function toggleSale() external onlyOwner {
    saleEnabled = !saleEnabled;
  }

  function toggleOpenseaProxy() external onlyOwner {
    openseaProxyEnabled = !openseaProxyEnabled;
  }

  function toggleTransferLogic() external onlyOwner {
    transferLogicEnabled = !transferLogicEnabled;
  }

  function toggleUpgradeSameColony() external onlyOwner {
    upgradeSameColonyEnabled = !upgradeSameColonyEnabled;
  }

  function getTokenIDs(address addr) public view returns (uint256[] memory) {
    uint256 total = totalSupply();
    uint256 count = balanceOf(addr);
    uint256[] memory tokens = new uint256[](count);
    uint256 tokenIndex = 0;
    for (uint256 i; i < total; i++) {
      if (addr == ownerOf(i)) {
        tokens[tokenIndex] = i;
        tokenIndex++;
      }
    }
    return tokens;
  }

  function paidMint(uint256 amount) public nonReentrant {
    uint256 totalMinted = totalSupply();

    require(saleEnabled, "Sale not enabled");
    require(amount + totalMinted <= MAX_SUPPLY, "Please try minting with less, not enough supply!");

    oxgnToken.burn(_msgSender(), amount * mintPrice);

    _safeMint(_msgSender(), amount);
  }

  /** OPENSEA */

  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    if (isValidOpenseaProxy(owner, operator)) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  function isValidOpenseaProxy(address owner, address operator) public view returns (bool) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }
    return false;
  }

  mapping(uint256 => uint256[]) public tokenToTransferTimestamp;
  mapping(uint256 => uint256[]) public tokenToResetTimestamp;
  mapping(uint256 => mapping(address => bool)) public tokenToBlacklist;

  function transferTimestamps(uint256 tokenId) public view returns (uint256[] memory) {
    return tokenToTransferTimestamp[tokenId];
  }

  function resetTimestamps(uint256 tokenId) public view returns (uint256[] memory) {
    return tokenToResetTimestamp[tokenId];
  }

  function updateLandLogic(
    address from,
    address to,
    uint256 tokenId
  ) private {
    if (!transferLogicEnabled) {
      return;
    }

    // Track all transfers to reset staked NFT's timestamps on new owner
    tokenToTransferTimestamp[tokenId].push(block.timestamp);

    bool updateLand = false;
    if (openseaProxyEnabled) {
      updateLand = isValidOpenseaProxy(from, _msgSender());
    } else {
      // Fallback - generic marketplace invoke check
      updateLand = (_msgSender().isContract() && tx.origin == to);
    }

    if (updateLand) {
      if (!tokenToBlacklist[tokenId][from]) {
        tokenToBlacklist[tokenId][from] = true;
      }

      if (!tokenToBlacklist[tokenId][to]) {
        tokenToResetTimestamp[tokenId].push(block.timestamp);
      }
    }
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    updateLandLogic(from, to, tokenId);
    ERC721A.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    updateLandLogic(from, to, tokenId);
    ERC721A.safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    updateLandLogic(from, to, tokenId);
    ERC721A.safeTransferFrom(from, to, tokenId, _data);
  }

  /** BUY UPGRADES */

  mapping(uint256 => mapping(uint256 => uint256)) public landToItem;

  function buyUpgrades(
    uint256 landTokenId,
    uint256 itemId,
    uint256 cost
  ) external {
    require(ownerOf(landTokenId) == _msgSender(), "You do not own this land!");

    uint256 itemColonyId = itemId % 3;
    if (itemColonyId < 1) {
      itemColonyId = 3;
    }

    Clans clansContract = Clans(clansAddress);
    (uint256 ownerColonyId, , ) = clansContract.clanStructs(_msgSender());

    if (upgradeSameColonyEnabled) {
      require(itemColonyId == ownerColonyId, "This item does not belong to your colony!");
    }

    oxgnToken.burn(_msgSender(), cost);
    landToItem[landTokenId][itemId] += cost;
  }

  /** STAKING */

  using Counters for Counters.Counter;
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;

  struct StakedContract {
    bool active;
    IERC721 instance;
  }
  mapping(address => StakedContract) public contracts;
  EnumerableSet.AddressSet activeContracts;

  modifier ifContractExists(address contractAddress) {
    require(activeContracts.contains(contractAddress), "Contract does not exists");
    _;
  }

  function addContract(address contractAddress) public onlyOwner {
    contracts[contractAddress].active = true;
    contracts[contractAddress].instance = IERC721(contractAddress);
    activeContracts.add(contractAddress);
  }

  function updateContract(address contractAddress, bool active) public onlyOwner ifContractExists(contractAddress) {
    require(activeContracts.contains(contractAddress), "Contract not added");
    contracts[contractAddress].active = active;
  }

  /** STAKE ON LAND - LAND OWNERS */

  mapping(address => mapping(uint256 => EnumerableSet.UintSet)) landToStakedTokensSetInternal;
  mapping(address => mapping(uint256 => uint256)) contractTokenIdToStakedTimestampInternal;

  function stakeInternal(
    address contractAddress,
    uint256[] memory tokenIds,
    uint256 landTokenId
  ) external nonReentrant {
    StakedContract storage _contract = contracts[contractAddress];
    require(_contract.active, "Token contract is not active");
    require(ownerOf(landTokenId) == _msgSender(), "You do not own this land!");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      _contract.instance.transferFrom(_msgSender(), address(this), tokenId);
      landToStakedTokensSetInternal[contractAddress][landTokenId].add(tokenId);
      contractTokenIdToStakedTimestampInternal[contractAddress][tokenId] = block.timestamp;

      emit StakeInternal(tokenId, contractAddress, _msgSender(), landTokenId);
    }
  }

  function unstakeInternal(
    address contractAddress,
    uint256[] memory tokenIds,
    uint256 landTokenId
  ) external ifContractExists(contractAddress) nonReentrant {
    require(ownerOf(landTokenId) == _msgSender(), "You do not own this land!");
    StakedContract storage _contract = contracts[contractAddress];

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(landToStakedTokensSetInternal[contractAddress][landTokenId].contains(tokenId), "Token is not staked");

      _contract.instance.transferFrom(address(this), _msgSender(), tokenId);
      landToStakedTokensSetInternal[contractAddress][landTokenId].remove(tokenId);
      delete contractTokenIdToStakedTimestampInternal[contractAddress][tokenId];

      emit UnstakeInternal(tokenId, contractAddress, _msgSender(), landTokenId);
    }
  }

  function stakedByOwnerInternal(address contractAddress, address owner)
    public
    view
    ifContractExists(contractAddress)
    returns (
      uint256[] memory stakedIds,
      uint256[] memory stakedTimestamps,
      uint256[] memory landIds
    )
  {
    uint256[] memory landTokens = getTokenIDs(owner);
    uint256 totalStakedTokens;
    for (uint256 i = 0; i < landTokens.length; i++) {
      EnumerableSet.UintSet storage userTokens = landToStakedTokensSetInternal[contractAddress][landTokens[i]];
      totalStakedTokens += userTokens.length();
    }

    if (totalStakedTokens > 0) {
      stakedIds = new uint256[](totalStakedTokens);
      stakedTimestamps = new uint256[](totalStakedTokens);
      landIds = new uint256[](totalStakedTokens);

      uint256 index;
      for (uint256 i = 0; i < landTokens.length; i++) {
        EnumerableSet.UintSet storage userTokens = landToStakedTokensSetInternal[contractAddress][landTokens[i]];
        for (uint256 j = 0; j < userTokens.length(); j++) {
          landIds[index] = landTokens[i];
          stakedIds[index] = userTokens.at(j);
          stakedTimestamps[index] = contractTokenIdToStakedTimestampInternal[contractAddress][userTokens.at(j)];
          index++;
        }
      }
    }

    return (stakedIds, stakedTimestamps, landIds);
  }

  function stakedByLandInternal(address contractAddress, uint256 landId)
    public
    view
    ifContractExists(contractAddress)
    returns (
      uint256[] memory stakedIds,
      uint256[] memory stakedTimestamps,
      address[] memory owners
    )
  {
    EnumerableSet.UintSet storage stakedTokens = landToStakedTokensSetInternal[contractAddress][landId];
    stakedIds = new uint256[](stakedTokens.length());
    stakedTimestamps = new uint256[](stakedTokens.length());
    owners = new address[](stakedTokens.length());

    for (uint256 i = 0; i < stakedTokens.length(); i++) {
      uint256 tokenId = stakedTokens.at(i);
      stakedIds[i] = tokenId;
      stakedTimestamps[i] = contractTokenIdToStakedTimestampInternal[contractAddress][tokenId];
      owners[i] = ownerOf(landId);
    }

    return (stakedIds, stakedTimestamps, owners);
  }

  function stakedByTokenInternal(address contractAddress, uint256 tokenId)
    public
    view
    ifContractExists(contractAddress)
    returns (
      address,
      uint256,
      uint256
    )
  {
    uint256 total = totalSupply();
    uint256 landId;
    address owner;
    for (uint256 i; i < total; i++) {
      if (landToStakedTokensSetInternal[contractAddress][i].contains(tokenId)) {
        landId = i;
        owner = ownerOf(i);
        break;
      }
    }
    return (owner, landId, contractTokenIdToStakedTimestampInternal[contractAddress][tokenId]);
  }

  /** STAKE ON LAND - EXTERNAL HELPERS */

  mapping(address => mapping(address => EnumerableSet.UintSet)) addressToStakedTokensSet;
  mapping(address => mapping(uint256 => address)) contractTokenIdToOwner;
  mapping(address => mapping(uint256 => uint256)) contractTokenIdToStakedTimestamp;
  mapping(address => mapping(uint256 => EnumerableSet.UintSet)) landToStakedTokensSet;
  mapping(address => mapping(address => EnumerableSet.UintSet)) addressToLandTokensSet;

  function stake(
    address contractAddress,
    uint256[] memory tokenIds,
    uint256 landTokenId
  ) external nonReentrant {
    StakedContract storage _contract = contracts[contractAddress];
    require(_contract.active, "Token contract is not active");
    require(landTokenId < totalSupply(), "Value higher than total supply");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      contractTokenIdToOwner[contractAddress][tokenId] = _msgSender();
      _contract.instance.transferFrom(_msgSender(), address(this), tokenId);
      addressToStakedTokensSet[contractAddress][_msgSender()].add(tokenId);
      landToStakedTokensSet[contractAddress][landTokenId].add(tokenId);
      contractTokenIdToStakedTimestamp[contractAddress][tokenId] = block.timestamp;

      emit Stake(tokenId, contractAddress, _msgSender(), landTokenId);
    }

    if (!addressToLandTokensSet[contractAddress][_msgSender()].contains(landTokenId)) {
      addressToLandTokensSet[contractAddress][_msgSender()].add(landTokenId);
    }
  }

  function unstake(
    address contractAddress,
    uint256[] memory tokenIds,
    uint256 landTokenId
  ) external ifContractExists(contractAddress) nonReentrant {
    StakedContract storage _contract = contracts[contractAddress];

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(addressToStakedTokensSet[contractAddress][_msgSender()].contains(tokenId), "Token is not staked");

      delete contractTokenIdToOwner[contractAddress][tokenId];
      _contract.instance.transferFrom(address(this), _msgSender(), tokenId);
      addressToStakedTokensSet[contractAddress][_msgSender()].remove(tokenId);
      landToStakedTokensSet[contractAddress][landTokenId].remove(tokenId);
      delete contractTokenIdToStakedTimestamp[contractAddress][tokenId];

      emit Unstake(tokenId, contractAddress, _msgSender(), landTokenId);
    }

    EnumerableSet.UintSet storage userTokens = addressToStakedTokensSet[contractAddress][_msgSender()];
    bool allRemovedFromLand = true;
    for (uint256 i = 0; i < userTokens.length(); i++) {
      if (landToStakedTokensSet[contractAddress][landTokenId].contains(userTokens.at(i))) {
        allRemovedFromLand = false;
        break;
      }
    }
    if (allRemovedFromLand) {
      addressToLandTokensSet[contractAddress][_msgSender()].remove(landTokenId);
    }
  }

  function stakedByOwner(address contractAddress, address owner)
    public
    view
    ifContractExists(contractAddress)
    returns (
      uint256[] memory stakedIds,
      uint256[] memory stakedTimestamps,
      uint256[] memory landIds
    )
  {
    EnumerableSet.UintSet storage userTokens = addressToStakedTokensSet[contractAddress][owner];
    stakedIds = new uint256[](userTokens.length());
    stakedTimestamps = new uint256[](userTokens.length());
    landIds = new uint256[](userTokens.length());

    for (uint256 i = 0; i < userTokens.length(); i++) {
      uint256 tokenId = userTokens.at(i);
      stakedIds[i] = tokenId;
      stakedTimestamps[i] = contractTokenIdToStakedTimestamp[contractAddress][tokenId];

      EnumerableSet.UintSet storage landTokens = addressToLandTokensSet[contractAddress][owner];
      for (uint256 j = 0; j < landTokens.length(); j++) {
        if (landToStakedTokensSet[contractAddress][landTokens.at(j)].contains(tokenId)) {
          landIds[i] = landTokens.at(j);
        }
      }
    }

    return (stakedIds, stakedTimestamps, landIds);
  }

  function stakedByLand(address contractAddress, uint256 landId)
    public
    view
    ifContractExists(contractAddress)
    returns (
      uint256[] memory stakedIds,
      uint256[] memory stakedTimestamps,
      address[] memory owners
    )
  {
    EnumerableSet.UintSet storage stakedTokens = landToStakedTokensSet[contractAddress][landId];
    stakedIds = new uint256[](stakedTokens.length());
    stakedTimestamps = new uint256[](stakedTokens.length());
    owners = new address[](stakedTokens.length());

    for (uint256 i = 0; i < stakedTokens.length(); i++) {
      uint256 tokenId = stakedTokens.at(i);
      stakedIds[i] = tokenId;
      stakedTimestamps[i] = contractTokenIdToStakedTimestamp[contractAddress][tokenId];
      owners[i] = contractTokenIdToOwner[contractAddress][tokenId];
    }

    return (stakedIds, stakedTimestamps, owners);
  }

  function stakedByToken(address contractAddress, uint256 tokenId)
    public
    view
    ifContractExists(contractAddress)
    returns (
      address,
      uint256,
      uint256
    )
  {
    address owner = contractTokenIdToOwner[contractAddress][tokenId];
    uint256 landId;
    EnumerableSet.UintSet storage landTokens = addressToLandTokensSet[contractAddress][owner];
    for (uint256 i = 0; i < landTokens.length(); i++) {
      if (landToStakedTokensSet[contractAddress][landTokens.at(i)].contains(tokenId)) {
        landId = landTokens.at(i);
        break;
      }
    }
    return (owner, landId, contractTokenIdToStakedTimestamp[contractAddress][tokenId]);
  }

  /** OXGN TANK */

  mapping(address => uint8) _addressToTankLevel;
  uint256[] public tankPrices = [500 ether, 1000 ether, 2000 ether, 4000 ether, 8000 ether, 16000 ether, 32000 ether, 64000 ether, 128000 ether];

  function upgradeTank() external nonReentrant {
    require(tankLevelOfOwner(_msgSender()) < tankPrices.length + 1, "Tank is at max level");
    oxgnToken.burn(_msgSender(), nextLevelTankPrice(_msgSender()));
    _addressToTankLevel[_msgSender()]++;
  }

  function upgradeTankAccount(address receiver) external onlyOwner {
    require(tankLevelOfOwner(receiver) < tankPrices.length + 1, "Tank is at max level");
    _addressToTankLevel[receiver]++;
  }

  function nextLevelTankPrice(address owner) public view returns (uint256) {
    return tankPrices[_addressToTankLevel[owner]];
  }

  function tankLevelOfOwner(address owner) public view returns (uint256) {
    return _addressToTankLevel[owner] + 1;
  }

  function setTankPrices(uint256[] memory newPrices) external onlyOwner {
    tankPrices = newPrices;
  }
}
