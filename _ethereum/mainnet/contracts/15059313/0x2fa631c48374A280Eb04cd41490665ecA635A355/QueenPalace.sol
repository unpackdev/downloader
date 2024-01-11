// SPDX-License-Identifier: MIT

/// @title Contract that handles all of Queen's Staff

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

import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./ERC165Storage.sol";

import "./RoyalLibrary.sol";
import "./IQueenPalace.sol";
import "./IQueenLab.sol";
import "./IQueenTraits.sol";
import "./IQueenE.sol";
import "./IQueenAuctionHouse.sol";
import "./IBaseContractController.sol";
import "./IRoyalTower.sol";
import "./QueenAuctionHouseProxy.sol";
import "./QueenAuctionHouseProxyAdmin.sol";

contract QueenPalace is
  IQueenPalace,
  Pausable,
  ReentrancyGuard,
  Ownable,
  ERC165Storage
{
  using EnumerableSet for EnumerableSet.AddressSet;

  event ArtistSet(address indexed artistAddress);
  event ArtistAllowed(address indexed artistAddress);
  event ArtistDisallowed(address indexed artistAddress);
  event DeveloperAllowed(address indexed artistAddress);
  event DeveloperDisallowed(address indexed artistAddress);
  event DeveloperSet(address indexed developerAddress);
  event DAOSet(address indexed addressDAO);
  event DAOExecutorSet(address indexed addressDAOExecutor);
  event LabSet(IQueenLab queenLab);
  event StorageSet(IQueenTraits queenStorage);
  event QueenESet(IQueenE _queenE);
  event RoyalTowerSet(address indexed _royalTower);
  event AuctionHouseProxySet(QueenAuctionHouseProxy queenAuctionHouseProxy);
  event ImplementationEnded(address indexed _address);
  event MinterUpdate(address indexed _address);

  event WhiteList(address addr);
  event ClearedWhiteList(address sender);

  address public _minter;
  address public override royalMuseum;
  address payable internal _artist;
  address payable internal _developer;
  address payable internal queeneDAO;
  address payable internal queeneDAOExecutor;
  address internal _royalTower;
  EnumerableSet.AddressSet internal _allowedArtists;
  EnumerableSet.AddressSet internal _allowedDevelopers;
  EnumerableSet.AddressSet internal whiteList;

  uint256 public override whiteListed;

  IQueenTraits internal queenStorage;
  IQueenLab internal queenLab;
  IQueenE internal queenE;
  QueenAuctionHouseProxyAdmin internal royalAuctionHouseProxyAdmin;
  QueenAuctionHouseProxy internal royalAuctionHouseProxy;

  bool internal onImplementation;

  constructor(
    address _artistAddress,
    address _developerAddress,
    address _royalMuseum
  ) {
    onImplementation = true;
    _artist = payable(_artistAddress);
    _developer = payable(_developerAddress);
    royalMuseum = _royalMuseum;

    _registerInterface(type(IQueenPalace).interfaceId);
  }

  /**
   *IN
   *OUT
   */
  function implementationEnded() external onlyOwner {
    onImplementation = false;

    emit ImplementationEnded(msg.sender);
  }

  /**
   *IN
   *OUT
   *status: current implementation status
   */
  function isOnImplementation() public view override returns (bool) {
    return onImplementation;
  }

  /**
   * @notice Require that message sender is either owner or artist chief.
   */
  modifier onlyOwnerOrChiefArtist() {
    isOwnerOrChiefArtist();
    _;
  }
  /**
   * @notice Require that message sender is either owner or artist/allowed.
   */
  modifier onlyOwnerOrArtist() {
    isOwnerOrArtist();

    _;
  }

  /**
   * @notice Require that message sender is either owner or developer/allowed.
   */
  modifier onlyOwnerOrDeveloper() {
    isOwnerOrDeveloper();

    _;
  }

  /**
   * @notice Require that message sender is either owner or developer/allowed or DAO Executor.
   */
  modifier onlyOwnerOrDeveloperOrDAO() {
    isOwnerOrDeveloperOrDAO();

    _;
  }

  /**
   * @notice Require that message sender is either owner or chief developer.
   */
  modifier onlyOwnerOrChiefDeveloper() {
    isOwnerOrChiefDeveloper();

    _;
  }

  /**
   * @notice Require that message sender is either owner or DAO contract.
   */
  modifier onlyOwnerOrDAO() {
    isOwnerOrDAO();

    _;
  }

  /**
   * @notice Require that message sender is either owner or DAO contract.
   */
  modifier onlyOwnerOrAuctionHouse() {
    isOwnerOrAuctionHouseProxy();

    _;
  }

  /**
   * @notice Require that message sender is either DAO or Contract On Implementation.
   */
  modifier onlyOnImplementationOrDAO() {
    isOnImplementationOrDAO();

    _;
  }

  function isOnImplementationOrDAO() internal view {
    require(
      isOnImplementation() || msg.sender == queeneDAOExecutor,
      "Not Implementation, DAO"
    );
  }

  function isOwnerOrAuctionHouseProxy() internal view {
    require(
      msg.sender == owner() || msg.sender == address(royalAuctionHouseProxy),
      "Not Owner, Auction House"
    );
  }

  function isOwnerOrDAO() internal view {
    require(
      msg.sender == owner() || msg.sender == queeneDAOExecutor,
      "Not Owner, DAO"
    );
  }

  function isOwnerOrChiefDeveloper() internal view {
    require(
      msg.sender == owner() || msg.sender == _developer,
      "Not Owner, Chief Developer"
    );
  }

  function isOwnerOrDeveloper() internal view {
    require(
      msg.sender == owner() || isDeveloper(msg.sender),
      "Not Owner, Developer"
    );
  }

  function isOwnerOrChiefArtist() internal view {
    require(
      msg.sender == owner() || msg.sender == _artist,
      "Not Owner, Chief Artist"
    );
  }

  function isOwnerOrArtist() internal view {
    require(msg.sender == owner() || isArtist(msg.sender), "Not Owner, Artist");
  }

  function isOwnerOrDeveloperOrDAO() internal view {
    require(
      msg.sender == owner() ||
        isDeveloper(msg.sender) ||
        msg.sender == queeneDAOExecutor,
      "Not Owner, Developer, DAO"
    );
  }

  /************************** vARTIST REGION ******************************************************** */

  /**
   *IN
   *OUT
   *currentArtit: current artist address allowed on contract
   */
  function artist() external view override returns (address) {
    return _artist;
  }

  /**
   *IN
   *OUT
   *bool: if address is artist chief or allowed artist
   */
  function isArtist(address addr) public view override returns (bool) {
    return _artist == addr || _allowedArtists.contains(addr);
  }

  /**
   *IN
   *_newArtist: address of artist tha will upload arts to contract
   *OUT
   */
  function setArtist(address _newArtist)
    external
    nonReentrant
    whenNotPaused
    onlyOwnerOrArtist
    returns (address newArtist)
  {
    require(
      _newArtist != RoyalLibrary.burnAddress,
      "Invalid artist address! Burn address!"
    );

    require(!Address.isContract(_newArtist), "Must be a wallet address!");

    _artist = payable(_newArtist);

    emit ArtistSet(_newArtist);

    return _artist;
  }

  /**
   *IN
   *_newArtist: address of artists allowed to upload arts to contract
   *OUT
   */
  function allowArtist(address _allowedArtist)
    external
    whenNotPaused
    onlyOwnerOrChiefArtist
    returns (address newArtist)
  {
    require(
      _allowedArtist != RoyalLibrary.burnAddress,
      "Invalid artist address! Burn address!"
    );

    require(!Address.isContract(_allowedArtist), "Must be a wallet address!");
    require(
      !_allowedArtists.contains(_allowedArtist),
      "Wallet already allowed!"
    );

    _allowedArtists.add(payable(_allowedArtist));

    emit ArtistAllowed(_allowedArtist);

    return _allowedArtist;
  }

  /**
   *IN
   *_newArtist: address of artists allowed to upload arts to contract
   *OUT
   */
  function disallowArtist(address _disallowedArtist)
    external
    whenNotPaused
    onlyOwnerOrChiefArtist
    returns (address newArtist)
  {
    require(
      _disallowedArtist != RoyalLibrary.burnAddress,
      "Invalid artist address! Burn address!"
    );

    require(
      !Address.isContract(_disallowedArtist),
      "Must be a wallet address!"
    );
    require(
      _allowedArtists.contains(_disallowedArtist),
      "Wallet not allowed allowed!"
    );

    _allowedArtists.remove(payable(_disallowedArtist));

    emit ArtistDisallowed(_disallowedArtist);

    return _disallowedArtist;
  }

  /************************** ^ARTIST REGION ******************************************************** */
  /************************** vDEV REGION *********************************************************** */

  /**
   *IN
   *OUT
   *currentDev: current dev address allowed on contract
   */
  function developer() external view override returns (address) {
    return _developer;
  }

  /**
   *IN
   *OUT
   *bool: if address is developer chief or allowed developer
   */
  function isDeveloper(address devAddr) public view override returns (bool) {
    return _developer == devAddr || _allowedDevelopers.contains(devAddr);
  }

  /**
     *IN
     *_developer: address of developer team responsable for contract updates propositions
     and implementation end
     *OUT
     */
  function setDeveloper(address _dev)
    external
    whenNotPaused
    onlyOwnerOrChiefDeveloper
    returns (address newDeveloper)
  {
    require(
      _dev != RoyalLibrary.burnAddress,
      "Invalid dev address! Burn address!"
    );

    require(!Address.isContract(_dev), "Must be a wallet address!");

    _developer = payable(_dev);

    emit DeveloperSet(_developer);

    return _developer;
  }

  /**
   *IN
   *_allowedDeveloper: address of developer allowed to interact with contract
   *OUT
   */
  function allowDeveloper(address _allowedDeveloper)
    external
    nonReentrant
    whenNotPaused
    onlyOwnerOrChiefDeveloper
    returns (address allowedDeveloper)
  {
    return _allowDeveloper(_allowedDeveloper);
  }

  /**
   *IN
   *_allowedDeveloper: address of artists allowed to upload arts to contract
   *OUT
   */
  function _allowDeveloper(address _allowedDeveloper)
    private
    returns (address)
  {
    require(
      _allowedDeveloper != RoyalLibrary.burnAddress,
      "Invalid developer address! Burn address!"
    );

    require(
      !Address.isContract(_allowedDeveloper),
      "Must be a wallet address!"
    );
    require(
      !_allowedDevelopers.contains(_allowedDeveloper),
      "Wallet already allowed!"
    );

    _allowedDevelopers.add(payable(_allowedDeveloper));

    emit DeveloperAllowed(_allowedDeveloper);

    return _allowedDeveloper;
  }

  /**
   *IN
   *_newArtist: address of artists allowed to upload arts to contract
   *OUT
   */
  function disallowDeveloper(address _disallowedDeveloper)
    external
    nonReentrant
    whenNotPaused
    onlyOwnerOrChiefDeveloper
    returns (address disallowedDeveloper)
  {
    return _disallowDeveloper(_disallowedDeveloper);
  }

  /**
   *IN
   *_newArtist: address of artists allowed to upload arts to contract
   *OUT
   */
  function _disallowDeveloper(address _disallowedDeveloper)
    private
    returns (address)
  {
    require(
      _disallowedDeveloper != RoyalLibrary.burnAddress,
      "Invalid developer address! Burn address!"
    );

    require(
      !Address.isContract(_disallowedDeveloper),
      "Must be a wallet address!"
    );
    require(
      _allowedDevelopers.contains(_disallowedDeveloper),
      "Wallet not allowed allowed!"
    );

    _allowedDevelopers.remove(payable(_disallowedDeveloper));

    emit DeveloperDisallowed(_disallowedDeveloper);

    return _disallowedDeveloper;
  }

  /************************** ^DEV REGION *********************************************************** */

  /************************** vDAO REGION *********************************************************** */

  /**
   *IN
   *_addressDAO: address of DAO contract
   *OUT
   */
  function setDAO(address payable _addressDAO)
    external
    whenNotPaused
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    require(
      _addressDAO != RoyalLibrary.burnAddress,
      "Invalid DAO address! Burn address!"
    );

    require(Address.isContract(_addressDAO), "Invalid DAO Contract!");

    queeneDAO = _addressDAO;

    emit DAOSet(_addressDAO);
  }

  /**
   *IN
   *OUT
   *currentDAO: current DAO contract address
   */
  function dao() external view override returns (address) {
    return queeneDAO;
  }

  /**
   *IN
   *_addressDAO: address of Royal Executor contract
   *OUT
   */
  function setDAOExecutor(address payable _addressDAOExecutor)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    require(
      _addressDAOExecutor != RoyalLibrary.burnAddress,
      "Invalid Royal Executor!"
    );

    require(
      Address.isContract(_addressDAOExecutor),
      "Invalid Executor Contract!"
    );

    queeneDAOExecutor = _addressDAOExecutor;

    emit DAOExecutorSet(_addressDAOExecutor);
  }

  /**
   *IN
   *OUT
   *currentDAO: current DAO contract address
   */
  function daoExecutor() external view override returns (address) {
    return queeneDAOExecutor;
  }

  /************************** ^DAO REGION *********************************************************** */

  /************************** vROYAL TOWER REGION *************************************************** */

  /**
   *IN
   *_addressRoyalTower: address of Royal Tower contract
   *OUT
   */
  function setRoyalTower(address payable _addressRoyalTower)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    require(
      _addressRoyalTower != RoyalLibrary.burnAddress,
      "Invalid Royal Tower address! Burn address!"
    );
    require(
      Address.isContract(_addressRoyalTower),
      "Invalid Royal Tower Contract!"
    );
    require(
      IRoyalTower(_addressRoyalTower).supportsInterface(
        type(IRoyalTower).interfaceId
      ),
      "Dont implement IRoyalTower interface!"
    );

    _royalTower = _addressRoyalTower;

    emit RoyalTowerSet(_royalTower);
  }

  /**
   *IN
   *OUT
   *currentRoyalTower: current Royal Tower contract address
   */
  function RoyalTowerAddr() external view override returns (address) {
    return _royalTower;
  }

  /************************** ^ROYAL TOWER REGION *************************************************** */

  /************************** vMINTER REGION ******************************************************** */

  /**
   * @notice Set the token minter.
   * @dev Only callable by the owner when not locked.
   */
  function setMinter(address _minterAddress)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    _minter = _minterAddress;

    emit MinterUpdate(_minterAddress);
  }

  /**
   *IN
   *OUT
   *currentDAO: current DAO contract address
   */
  function minter() external view override returns (address) {
    return _minter;
  }

  /************************** ^MINTER REGION ******************************************************** */

  /************************** vQUEENLAB REGION *********************************************************** */

  /**
   *IN
   *OUT
   *returns: current lab Contract
   */
  function QueenLab() external view override returns (IQueenLab) {
    return queenLab;
  }

  /**
   *IN
   *_labContract: queens lab contract
   *OUT
   */
  function setQueenLab(IQueenLab _labContract)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    require(
      _labContract.supportsInterface(type(IQueenLab).interfaceId),
      "Dont implement IQueenLab interface!"
    );

    queenLab = _labContract;

    emit LabSet(_labContract);
  }

  /************************** ^QUEENLAB REGION *********************************************************** */

  /************************** vQUEENTRAITS REGION *********************************************************** */

  /**
   *IN
   *OUT
   *returns: current queens trait storage Contract
   */
  function QueenTraits() external view override returns (IQueenTraits) {
    return queenStorage;
  }

  /**
   *IN
   *_storageAddress: address of queens trait storage contract
   *OUT
   */
  function setQueenStorage(IQueenTraits _storageContract)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    require(
      _storageContract.supportsInterface(type(IQueenTraits).interfaceId),
      "Dont implement correct interface!"
    );

    queenStorage = _storageContract;

    emit StorageSet(_storageContract);
  }

  /************************** ^QUEENTRAITS REGION *********************************************************** */

  /************************** vROYALAUCTIONHOUSE REGION ***************************************************** */

  /**
   *IN
   *OUT
   *returns: current queens auction house Contract through proxy
   */
  function QueenAuctionHouse()
    public
    view
    override
    returns (IQueenAuctionHouse)
  {
    return
      IQueenAuctionHouse(
        royalAuctionHouseProxyAdmin.getProxyImplementation(
          royalAuctionHouseProxy
        )
      );
  }

  /**
   *IN
   *OUT
   *returns: current queens auction house proxy address
   */
  function QueenAuctionHouseProxyAddr() public view override returns (address) {
    return address(royalAuctionHouseProxy);
  }

  /**
   *IN
   *_auctionHouseContract: queens auction house contract
   *OUT
   */
  function setQueenAuctionHouseProxy(
    QueenAuctionHouseProxy _auctionHouseContractProxy,
    QueenAuctionHouseProxyAdmin _auctionHouseContractProxyAdmin
  ) external whenNotPaused onlyOwnerOrDeveloperOrDAO onlyOnImplementationOrDAO {
    royalAuctionHouseProxy = _auctionHouseContractProxy;
    royalAuctionHouseProxyAdmin = _auctionHouseContractProxyAdmin;

    emit AuctionHouseProxySet(_auctionHouseContractProxy);
  }

  /************************** ^ROYALAUCTIONHOUSE REGION ***************************************************** */

  /************************** vQUEENE REGION **************************************************************** */

  /**
   *IN
   *OUT
   *returns: current queene Contract
   */
  function QueenE() external view override returns (IQueenE) {
    return queenE;
  }

  /**
   *IN
   *_queenE: queene contract
   *OUT
   */
  function setQueenE(IQueenE _queenE)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    require(
      _queenE.supportsInterface(type(IQueenE).interfaceId),
      "QueenE Dont implement correct interface!"
    );

    queenE = _queenE;

    emit QueenESet(_queenE);
  }

  /************************** ^QUEENE REGION **************************************************************** */

  /************************** vWHITELIST REGION ************************************************************* */

  /**
   * @notice WHITELIST ADDRESS.
   */
  function whiteListAddress(address[] calldata _whiteListed)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    require(_whiteListed.length > 0, "Empty List");
    //add address to whitelist
    for (uint256 idx = 0; idx < _whiteListed.length; idx++) {
      if (!whiteList.contains(_whiteListed[idx])) {
        whiteList.add(_whiteListed[idx]);
        whiteListed++;
        emit WhiteList(_whiteListed[idx]);
      }
    }
  }

  /**
   * @notice Clear whitelist address.
   */
  function clearWhiteList()
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    //add address to whitelist
    for (uint256 idx = 0; idx < whiteList.length(); idx++) {
      whiteList.remove(whiteList.at(idx));
    }
    emit ClearedWhiteList(msg.sender);
  }

  /**
   * @notice return true if address is permited to bid (whitelist empty or address on whitelist).
   */
  function isWhiteListed(address _addr) external view returns (bool) {
    //add address to whitelist
    return whiteList.length() == 0 ? true : whiteList.contains(_addr);
  }

  /**
   * @notice return true if address is on whitelist.
   */
  function whiteListContains(address _addr) external view returns (bool) {
    return whiteList.contains(_addr);
  }
  /************************** ^WHITELIST REGION ************************************************************* */
}
