// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.6.12;

//
//                     _░▒███████
//                     ░██▓▒░░▒▓██
//                     ██▓▒░__░▒▓██___██████
//                     ██▓▒░____░▓███▓__░▒▓██
//                     ██▓▒░___░▓██▓_____░▒▓██
//                     ██▓▒░_______________░▒▓██
//                     _██▓▒░______________░▒▓██
//                     __██▓▒░____________░▒▓██
//                     ___██▓▒░__________░▒▓██
//                     ____██▓▒░________░▒▓██
//                     _____██▓▒░_____░▒▓██
//　　██░▀██████████████▀░██_██▓▒░__░▒▓██
//　　█▌▒▒░████████████░▒▒▐█__█▓▒░░▒▓██
//　　█░▒▒▒░██████████░▒▒▒░█____░▒▓██
//　　▌░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▐__░▒▓██
//　　░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▓██
//　 ███▀▀▀██▄▒▒▒▒▒▒▒▄██▀▀▀██
//　 ██░░░▐█░▀█▒▒▒▒▒█▀░█▌░░░█ 
//　 ▐▌░░░▐▄▌░▐▌▒▒▒▐▌░▐▄▌░░▐▌
//　　█░░░▐█▌░░▌▒▒▒▐░░▐█▌░░█
//　　▒▀▄▄▄█▄▄▄▌░▄░▐▄▄▄█▄▄▀▒
//　　░░░░░░░░░░└┴┘░░░░░░░░░
//　　██▄▄░░░░░░░░░░░░░░▄▄██
//　　████████▒▒▒▒▒▒████████
//　　█▀░░███▒▒░░▒░░▒▀██████
//　　█▒░███▒▒╖░░╥░░╓▒▐█████
//　　█▒░▀▀▀░░║░░║░░║░░█████
//　　██▄▄▄▄▀▀┴┴╚╧╧╝╧╧╝┴┴███
//　　██████████████████████
//

import "./AccessControl.sol";
import "./Ownable.sol";

// ERC721
import "./ERC721.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

// ERC20
import "./IERC20.sol";
import "./SafeERC20.sol";

// For safe maths operations
import "./SafeMath.sol";

// Utils only
import "./StringsUtil.sol";

interface IERC20Burnable {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function burnAmount() external view returns (uint256 _amount);
}

/**
* @title NotRealDigitalAsset - V2
*
* http://www.notreal.ai/
*
* ERC721 compliant digital assets for real-world artwork.
*
* Base NFT Issuance Contract
*
* AMPLIFY ART.
*
*/
contract NotRealDigitalAssetV2 is
AccessControl,
Ownable,
ERC721,
Pausable,
ReentrancyGuard
{

  bytes32 public constant ROLE_NOT_REAL = keccak256('ROLE_NOT_REAL');
  bytes32 public constant ROLE_MINTER = keccak256('ROLE_MINTER');
  bytes32 public constant ROLE_MARKET = keccak256('ROLE_MARKET');

  ///////////////
  // Modifiers //
  ///////////////

  // Modifiers are wrapped around functions because it shaves off contract size 
  modifier onlyAvailableEdition(uint256 _editionNumber, uint256 _numTokens) {
    _onlyAvailableEdition(_editionNumber, _numTokens);
    _;
  }

  modifier onlyActiveEdition(uint256 _editionNumber) {
    _onlyActiveEdition(_editionNumber);
    _;
  }

  modifier onlyRealEdition(uint256 _editionNumber) {
    _onlyRealEdition(_editionNumber);
    _;
  }

  modifier onlyValidTokenId(uint256 _tokenId) {
    _onlyValidTokenId(_tokenId);
    _;
  }

  modifier onlyPurchaseDuringWindow(uint256 _editionNumber) {
    _onlyPurchaseDuringWindow(_editionNumber);
    _;
  }

  function _onlyAvailableEdition(uint256 _editionNumber, uint256 _numTokens) internal view {
    require(editionNumberToEditionDetails[_editionNumber].totalSupply.add(_numTokens) <= editionNumberToEditionDetails[_editionNumber].totalAvailable);
  }

  function _onlyActiveEdition(uint256 _editionNumber) internal view {
    require(editionNumberToEditionDetails[_editionNumber].active);
  }

  function _onlyRealEdition(uint256 _editionNumber) internal view {
    require(editionNumberToEditionDetails[_editionNumber].editionNumber > 0);
  }

  function _onlyValidTokenId(uint256 _tokenId) internal view {
    require(_exists(_tokenId));
  }

  function _onlyPurchaseDuringWindow(uint256 _editionNumber) internal view {
    require(editionNumberToEditionDetails[_editionNumber].startDate <= block.timestamp);
    require(editionNumberToEditionDetails[_editionNumber].endDate >= block.timestamp);
  }

  modifier onlyIfNotReal() {
    _onlyIfNotReal();
    _;
  }

  modifier onlyIfMinter() {
    _onlyIfMinter();
    _;
  }

  function _onlyIfNotReal()  internal view {
    require(_msgSender() == owner() || hasRole(ROLE_NOT_REAL, _msgSender()));
  }

  function _onlyIfMinter() internal view {
    require(_msgSender() == owner() || hasRole(ROLE_NOT_REAL, _msgSender()) || hasRole(ROLE_MINTER, _msgSender()));
  }

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  ////////////
  // Events //
  ////////////

  // Emitted on purchases from within this contract
  event Purchase(
    uint256 indexed _tokenId,
    uint256 indexed _editionNumber,
    address indexed _buyer,
    uint256 _priceInWei,
    uint256 _numTokens
  );

  // Emitted on every mint
  event Minted(
    uint256 indexed _tokenId,
    uint256 indexed _editionNumber,
    address indexed _buyer,
    uint256 _numTokens
  );

  // Emitted on every edition created
  event EditionCreated(
    uint256 indexed _editionNumber,
    bytes32 indexed _editionData,
    uint256 indexed _editionType
  );

  event NameChange(uint256 indexed _tokenId, string _newName);

  ////////////////
  // Properties //
  ////////////////

  uint256 constant internal MAX_UINT32 = ~uint32(0);

  string public tokenBaseURI = "https://ipfs.infura.io/ipfs/";

  // simple counter to keep track of the highest edition number used
  uint256 public highestEditionNumber;

  // number of assets minted of any type
  uint256 public totalNumberMinted;

  // number of assets minted of any type
  uint256 public totalPurchaseValueInWei;

  // number of assets available of any type
  uint256 public totalNumberAvailable;

  // Max number of tokens that can be minted/purchased in a batch
  uint256 public maxBatch = 100;
  uint256 public maxGas = 100000000000;

  // the NR account which can receive commission
  address public nrCommissionAccount;

  // Accepted ERC20 token
  IERC20 public acceptedToken;

  IERC20Burnable public nameToken;

  // Optional commission split can be defined per edition
  mapping(uint256 => CommissionSplit) internal editionNumberToOptionalCommissionSplit;

  // Simple structure providing an optional commission split per edition purchase
  struct CommissionSplit {
    uint256 rate;
    address recipient;
  }

  // Object for edition details
  struct EditionDetails {
    // Identifiers
    uint256 editionNumber;    // the range e.g. 10000
    bytes32 editionData;      // some data about the edition
    uint256 editionType;      // e.g. 1 = NRDA, 4 = Deactivated
    // Config
    uint256 startDate;        // date when the edition goes on sale
    uint256 endDate;          // date when the edition is available until
    address artistAccount;    // artists account
    uint256 artistCommission; // base artists commission, could be overridden by external contracts
    uint256 priceInWei;       // base price for edition, could be overridden by external contracts
    string tokenURI;          // IPFS hash - see base URI
    bool active;              // Root control - on/off for the edition
    // Counters
    uint256 totalSupply;      // Total purchases or mints
    uint256 totalAvailable;   // Total number available to be purchased
  }

  // _editionNumber : EditionDetails
  mapping(uint256 => EditionDetails) internal editionNumberToEditionDetails;

  // _tokenId : _editionNumber
  mapping(uint256 => uint256) internal tokenIdToEditionNumber;

  // _editionNumber : [_tokenId, _tokenId]
  mapping(uint256 => uint256[]) internal editionNumberToTokenIds;
  mapping(uint256 => uint256[]) internal editionNumberToBurnedTokenIds;

  // _artistAccount : [_editionNumber, _editionNumber]
  mapping(address => uint256[]) internal artistToEditionNumbers;
  mapping(uint256 => uint256) internal editionNumberToArtistIndex;

  // _editionType : [_editionNumber, _editionNumber]
  mapping(uint256 => uint256[]) internal editionTypeToEditionNumber;
  mapping(uint256 => uint256) internal editionNumberToTypeIndex;

  mapping (uint256 => string) public tokenName;
  mapping (string => bool) internal reservedName;


  /*
   * Constructor
   */
  constructor (IERC20 _acceptedToken) public payable ERC721("NotRealDigitalAsset", "NRDA") {
    // set commission account to contract creator
    nrCommissionAccount = _msgSender();
    acceptedToken = _acceptedToken;

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setBaseURI(tokenBaseURI);
  }


  // Function wrapper for using native Ether or ERC20
  function _acceptedTokenSafeTransferFrom(address _from, address _to, uint256 _msgValue) internal {
    require(tx.gasprice <= maxGas, "Gas price too high");

    if(address(acceptedToken) == address(0)) {
      require(msg.value == _msgValue);
      require(_from == _msgSender());
      require(_to == address(this));
    } else {
      acceptedToken.safeTransferFrom(_from, _to, _msgValue);
    }
  }

  function _acceptedTokenSafeTransfer(address _to, uint256 _msgValue) internal {
    if(address(acceptedToken) == address(0)) {
      payable(_to).transfer(_msgValue);
    } else {
      acceptedToken.safeTransfer(_to, _msgValue);
    }
  }


  function pause() public onlyIfNotReal {
      _pause();
  }

  function unpause() public onlyIfNotReal {
      _unpause();
  }

  function setNameToken(address _nameToken) external onlyOwner {
      nameToken = IERC20Burnable(_nameToken);
  }

  // Spend name tokens to give this ERC721 a unique name
  function changeName(uint256 _tokenId, string memory _newName) public onlyValidTokenId(_tokenId) {
      string memory _newNameLower = StringsUtil.toLower(_newName);
  
      require(_msgSender() == ownerOf(_tokenId), "ERC721: caller is not the owner");
      require(StringsUtil.validateName(_newName), "Not a valid new name");
      require(!reservedName[_newNameLower], "Name already reserved");
  
      reservedName[StringsUtil.toLower(tokenName[_tokenId])] = false;
      reservedName[_newNameLower] = true;

      nameToken.burnFrom(_msgSender(), nameToken.burnAmount());
      tokenName[_tokenId] = _newName;
  
      emit NameChange(_tokenId, _newName);
  }

  function mint(address _to, uint256 _editionNumber)
  public
  onlyIfMinter
  returns (uint256) {
    return mintMany(_to, _editionNumber, 1);
  }

  /**
   * @dev Private (NR only) method for minting editions
   * @dev Payment not needed for this method
   */
  function mintMany(address _to, uint256 _editionNumber, uint256 _numTokens)
  public
  onlyIfMinter
  onlyRealEdition(_editionNumber)
  onlyAvailableEdition(_editionNumber, _numTokens)
  returns (uint256) {

    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    uint256 _tokenId = _editionDetails.editionNumber.add(_editionDetails.totalSupply).add(1);

    for (uint256 i = 0; i < _numTokens; i++) {
      // Construct next token ID e.g. 100000 + 1 = ID of 100001 (this first in the edition set)
      // Create the token
      _mintToken(_to, _tokenId.add(i), _editionNumber, _editionDetails.tokenURI);
    }

    totalNumberMinted = totalNumberMinted.add(_numTokens);
    _editionDetails.totalSupply = _editionDetails.totalSupply.add(_numTokens);

    // Emit minted event
    emit Minted(_tokenId, _editionNumber, _to, _numTokens);

    return _tokenId;
  }

  /**
   * @dev Internal factory method for building editions
   */
  function createEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string memory _tokenURI,
    uint256 _totalAvailable,
    bool _active
  )
  public
  onlyIfNotReal
  returns (bool)
  {
    // Prevent missing edition number
    require(_editionNumber != 0);

    // Prevent edition number lower than last one used
    require(_editionNumber > highestEditionNumber);

    // Check previously edition plus total available is less than new edition number
    require(highestEditionNumber.add(editionNumberToEditionDetails[highestEditionNumber].totalAvailable) < _editionNumber);

    // Prevent missing types
    require(_editionType != 0);

    // Prevent missing token URI
    require(bytes(_tokenURI).length != 0);

    // Prevent empty artists address
    require(_artistAccount != address(0));

    // Prevent invalid commissions
    require(_artistCommission <= 100 && _artistCommission >= 0);

    // Prevent duplicate editions
    require(editionNumberToEditionDetails[_editionNumber].editionNumber == 0);

    // Default end date to max uint256
    uint256 endDate = _endDate;
    if (_endDate == 0) {
      endDate = MAX_UINT32;
    }

    editionNumberToEditionDetails[_editionNumber] = EditionDetails({
      editionNumber : _editionNumber,
      editionData : _editionData,
      editionType : _editionType,
      startDate : _startDate,
      endDate : endDate,
      artistAccount : _artistAccount,
      artistCommission : _artistCommission,
      priceInWei : _priceInWei,
      tokenURI : StringsUtil.strConcat(_tokenURI, "/"),
      totalSupply : 0, // default to all available
      totalAvailable : _totalAvailable,
      active : _active
    });

    // Add to total available count
    totalNumberAvailable = totalNumberAvailable.add(_totalAvailable);

    // Update mappings
    _updateArtistLookupData(_artistAccount, _editionNumber);
    _updateEditionTypeLookupData(_editionType, _editionNumber);

    emit EditionCreated(_editionNumber, _editionData, _editionType);

    // Update the edition pointer if needs be
    highestEditionNumber = _editionNumber;

    return true;
  }

  function _updateEditionTypeLookupData(uint256 _editionType, uint256 _editionNumber) internal {
    uint256 typeEditionIndex = editionTypeToEditionNumber[_editionType].length;
    editionTypeToEditionNumber[_editionType].push(_editionNumber);
    editionNumberToTypeIndex[_editionNumber] = typeEditionIndex;
  }

  function _updateArtistLookupData(address _artistAccount, uint256 _editionNumber) internal {
    uint256 artistEditionIndex = artistToEditionNumbers[_artistAccount].length;
    artistToEditionNumbers[_artistAccount].push(_editionNumber);
    editionNumberToArtistIndex[_editionNumber] = artistEditionIndex;
  }


  ///**
  // * @dev Public entry point for purchasing an edition on behalf of someone else
  // * @dev Reverts if edition is invalid
  // * @dev Reverts if payment not provided in full
  // * @dev Reverts if edition is sold out
  // * @dev Reverts if edition is not active or available
  // */
  function purchaseMany(address _to, uint256 _editionNumber, uint256 _numTokens, uint256 _msgValue)
  public
  payable
  whenNotPaused
  nonReentrant
  onlyRealEdition(_editionNumber)
  onlyActiveEdition(_editionNumber)
  onlyAvailableEdition(_editionNumber, _numTokens)
  onlyPurchaseDuringWindow(_editionNumber)
  returns (uint256) {

    require(_numTokens <= maxBatch && _numTokens >= 1);
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];

    require(_msgValue >= _editionDetails.priceInWei.mul(_numTokens));
    _acceptedTokenSafeTransferFrom(_msgSender(), address(this), _msgValue);

    uint256 _tokenId = _editionDetails.editionNumber.add(_editionDetails.totalSupply).add(1);
    for (uint256 i = 0; i < _numTokens; i++) {
      // Transfer token to this contract
      // Construct next token ID e.g. 100000 + 1 = ID of 100001 (this first in the edition set)
      // Create the token
      _mintToken(_to, _tokenId.add(i), _editionNumber, _editionDetails.tokenURI);
    }

    totalNumberMinted = totalNumberMinted.add(_numTokens);
    _editionDetails.totalSupply = _editionDetails.totalSupply.add(_numTokens);

    // Splice funds and handle commissions
    _handleFunds(_editionNumber, _msgValue, _editionDetails.artistAccount, _editionDetails.artistCommission);

    // Emit minted event
    emit Minted(_tokenId, _editionNumber, _to, _numTokens);

    // Broadcast purchase
    emit Purchase(_tokenId, _editionNumber, _to, _editionDetails.priceInWei, _numTokens);

    return _tokenId;
  }


  function _nextTokenId(uint256 _editionNumber) internal returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];

    // Bump number totalSupply
    _editionDetails.totalSupply = _editionDetails.totalSupply.add(1);

    // Construct next token ID e.g. 100000 + 1 = ID of 100001 (this first in the edition set)
    return _editionDetails.editionNumber.add(_editionDetails.totalSupply);
  }

  function _mintToken(address _to, uint256 _tokenId, uint256 _editionNumber, string memory _tokenURI) internal {

    // Mint new base token
    super._mint(_to, _tokenId);
    super._setTokenURI(_tokenId, StringsUtil.strConcat(_tokenURI, StringsUtil.uint2str(_tokenId)));

    // Maintain mapping for tokenId to edition for lookup
    tokenIdToEditionNumber[_tokenId] = _editionNumber;

    // Maintain mapping of edition to token array for "edition minted tokens"
    editionNumberToTokenIds[_editionNumber].push(_tokenId);
  }

  function _handleFunds(uint256 _editionNumber, uint256 _priceInWei, address _artistAccount, uint256 _artistCommission) internal {

    // Extract the artists commission and send it
    uint256 artistPayment = _priceInWei.div(100).mul(_artistCommission);
    if (artistPayment > 0) {
      _acceptedTokenSafeTransfer(_artistAccount, artistPayment); 
    }

    // Load any commission overrides
    CommissionSplit storage commission = editionNumberToOptionalCommissionSplit[_editionNumber];

    // Apply optional commission structure
    uint256 rateSplit = 0;
    if (commission.rate > 0) {
      rateSplit = _priceInWei.div(100).mul(commission.rate);
      _acceptedTokenSafeTransfer(commission.recipient, rateSplit); 
    }

    // Send remaining eth to NR
    uint256 remainingCommission = _priceInWei.sub(artistPayment).sub(rateSplit);
    _acceptedTokenSafeTransfer(nrCommissionAccount, remainingCommission); 

    // Record wei sale value
    totalPurchaseValueInWei = totalPurchaseValueInWei.add(_priceInWei);
  }

  /**
   * @dev Private (NR only) method for burning tokens which have been created incorrectly
   */
  function burn(uint256 _tokenId) external onlyIfNotReal {

    // Clear from parents
    super._burn(_tokenId);

    // Get hold of the edition for cleanup
    uint256 _editionNumber = tokenIdToEditionNumber[_tokenId];

    // Delete token ID mapping
    delete tokenIdToEditionNumber[_tokenId];
    editionNumberToBurnedTokenIds[_editionNumber].push(_tokenId);
  }

  //////////////////
  // Base Updates //
  //////////////////
  //

  function updateTokenBaseURI(string calldata _newBaseURI)
  external
  onlyIfNotReal {
    require(bytes(_newBaseURI).length != 0);
    tokenBaseURI = _newBaseURI;
  }

  function updateNrCommissionAccount(address _nrCommissionAccount)
  external
  onlyIfNotReal {
    require(_nrCommissionAccount != address(0));
    nrCommissionAccount = _nrCommissionAccount;
  }

  function updateMaxBatch(uint256 _maxBatch)
  external
  onlyIfNotReal {
    maxBatch = _maxBatch;
  }

  function updateMaxGas(uint256 _maxGas)
  external
  onlyIfNotReal {
    maxGas = _maxGas;
  }

  /////////////////////
  // Edition Updates //
  /////////////////////

  function updateEditionTokenURI(uint256 _editionNumber, string calldata _uri)
  external
  onlyIfNotReal
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].tokenURI = StringsUtil.strConcat(_uri, "/");
  }

  function updatePriceInWei(uint256 _editionNumber, uint256 _priceInWei)
  external
  onlyIfNotReal
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].priceInWei = _priceInWei;
  }

  function updateArtistCommission(uint256 _editionNumber, uint256 _rate)
  external
  onlyIfNotReal
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].artistCommission = _rate;
  }
  

  function updateEditionType(uint256 _editionNumber, uint256 _editionType)
  external 
  onlyIfNotReal
  onlyRealEdition(_editionNumber) {

    EditionDetails storage _originalEditionDetails = editionNumberToEditionDetails[_editionNumber];

    // Get list of editions for old type
    uint256[] storage editionNumbersForType = editionTypeToEditionNumber[_originalEditionDetails.editionType];

    // Remove edition from old type list
    uint256 editionTypeIndex = editionNumberToTypeIndex[_editionNumber];
    delete editionNumbersForType[editionTypeIndex];

    // Add new type to the list
    uint256 newTypeEditionIndex = editionTypeToEditionNumber[_editionType].length;
    editionTypeToEditionNumber[_editionType].push(_editionNumber);
    editionNumberToTypeIndex[_editionNumber] = newTypeEditionIndex;

    // Update the edition
    _originalEditionDetails.editionType = _editionType;
  }
  
  function updateTotalSupply(uint256 _editionNumber, uint256 _totalSupply)
  external 
  onlyIfNotReal
  onlyRealEdition(_editionNumber) {
    require(editionNumberToTokenIds[_editionNumber].length <= _totalSupply);
    editionNumberToEditionDetails[_editionNumber].totalSupply = _totalSupply;
  }
  
  function updateTotalAvailable(uint256 _editionNumber, uint256 _totalAvailable)
  external
  onlyIfNotReal
  onlyRealEdition(_editionNumber) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];

    require(_editionDetails.totalSupply <= _totalAvailable);

    uint256 originalAvailability = _editionDetails.totalAvailable;
    _editionDetails.totalAvailable = _totalAvailable;
    totalNumberAvailable = totalNumberAvailable.sub(originalAvailability).add(_totalAvailable);
  }
  

  function updateActive(uint256 _editionNumber, bool _active)
  external 
  onlyIfNotReal
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].active = _active;
  }

  function updateStartDate(uint256 _editionNumber, uint256 _startDate)
  external
  onlyIfNotReal
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].startDate = _startDate;
  }

  function updateEndDate(uint256 _editionNumber, uint256 _endDate)
  external
  onlyRealEdition(_editionNumber) {
    require(_msgSender() == owner() || hasRole(ROLE_NOT_REAL, _msgSender()) || hasRole(ROLE_MARKET, _msgSender()));
    editionNumberToEditionDetails[_editionNumber].endDate = _endDate;
  }

  function updateArtistsAccount(uint256 _editionNumber, address _artistAccount)
  external
  onlyIfNotReal
  onlyRealEdition(_editionNumber) {

    EditionDetails storage _originalEditionDetails = editionNumberToEditionDetails[_editionNumber];

    uint256 editionArtistIndex = editionNumberToArtistIndex[_editionNumber];

    // Get list of editions old artist works with
    uint256[] storage editionNumbersForArtist = artistToEditionNumbers[_originalEditionDetails.artistAccount];

    // Remove edition from artists lists
    delete editionNumbersForArtist[editionArtistIndex];

    // Add new artists to the list
    uint256 newArtistsEditionIndex = artistToEditionNumbers[_artistAccount].length;
    artistToEditionNumbers[_artistAccount].push(_editionNumber);
    editionNumberToArtistIndex[_editionNumber] = newArtistsEditionIndex;

    // Update the edition
    _originalEditionDetails.artistAccount = _artistAccount;
  }

  function updateOptionalCommission(uint256 _editionNumber, uint256 _rate, address _recipient)
  external
  onlyIfNotReal
  onlyRealEdition(_editionNumber) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    uint256 artistCommission = _editionDetails.artistCommission;

    if (_rate > 0) {
      require(_recipient != address(0));
    }
    require(artistCommission.add(_rate) <= 100);

    editionNumberToOptionalCommissionSplit[_editionNumber] = CommissionSplit({rate : _rate, recipient : _recipient});
  }

  ///////////////////
  // Token Updates //
  ///////////////////

  function setTokenURI(uint256 _tokenId, string calldata _uri)
  external
  onlyIfNotReal
  onlyValidTokenId(_tokenId) {
    _setTokenURI(_tokenId, _uri);
  }

  ///////////////////
  // Query Methods //
  ///////////////////

  /**
   * @dev Lookup the edition of the provided token ID
   * @dev Returns 0 if not valid
   */
  function editionOfTokenId(uint256 _tokenId) external view returns (uint256 _editionNumber) {
    return tokenIdToEditionNumber[_tokenId];
  }

  /**
   * @dev Lookup all editions added for the given edition type
   * @dev Returns array of edition numbers, any zero edition ids can be ignore/stripped
   */
  function editionsOfType(uint256 _type) external view returns (uint256[] memory _editionNumbers) {
    return editionTypeToEditionNumber[_type];
  }

  /**
   * @dev Lookup all editions for the given artist account
   * @dev Returns empty list if not valid
   */
  function artistsEditions(address _artistsAccount) external view returns (uint256[] memory _editionNumbers) {
    return artistToEditionNumbers[_artistsAccount];
  }

  /**
   * @dev Lookup all tokens minted for the given edition number
   * @dev Returns array of token IDs, any zero edition ids can be ignore/stripped
   */
  function tokensOfEdition(uint256 _editionNumber) external view returns (uint256[] memory _tokenIds) {
    return editionNumberToTokenIds[_editionNumber];
  }

  /**
   * @dev Lookup all owned tokens for the provided address
   * @dev Returns array of token IDs
   */
  function tokensOf(address _owner) external view returns (uint256[] memory _tokenIds) {
    uint256[] memory results = new uint256[](balanceOf(_owner));

    for (uint256 idx = 0; idx < results.length; idx++) {
        results[idx] = tokenOfOwnerByIndex(_owner, idx);
    }

    return results;
  }

  /**
   * @dev Checks to see if the edition exists, assumes edition of zero is invalid
   */
  function editionExists(uint256 _editionNumber) external view returns (bool) {
    if (_editionNumber == 0) {
      return false;
    }
    EditionDetails storage editionNumber = editionNumberToEditionDetails[_editionNumber];
    return editionNumber.editionNumber == _editionNumber;
  }

  /**
   * @dev Checks to see if the token exists
   */
  function exists(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  /**
   * @dev Lookup any optional commission split set for the edition
   * @dev Both values will be zero if not present
   */
  function editionOptionalCommission(uint256 _editionNumber) external view returns (uint256 _rate, address _recipient) {
    CommissionSplit storage commission = editionNumberToOptionalCommissionSplit[_editionNumber];
    return (commission.rate, commission.recipient);
  }

  /**
   * @dev Main entry point for looking up edition config/metadata
   * @dev Reverts if invalid edition number provided
   */
  function detailsOfEdition(uint256 editionNumber)
  external view
  onlyRealEdition(editionNumber)
  returns (
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string memory _tokenURI,
    uint256 _totalSupply,
    uint256 _totalAvailable,
    bool _active
  ) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[editionNumber];
    return (
    _editionDetails.editionData,
    _editionDetails.editionType,
    _editionDetails.startDate,
    _editionDetails.endDate,
    _editionDetails.artistAccount,
    _editionDetails.artistCommission,
    _editionDetails.priceInWei,
    StringsUtil.strConcat(tokenBaseURI, _editionDetails.tokenURI),
    _editionDetails.totalSupply,
    _editionDetails.totalAvailable,
    _editionDetails.active
    );
  }

  /**
   * @dev Lookup a tokens common identifying characteristics
   * @dev Reverts if invalid token ID provided
   */
  function tokenData(uint256 _tokenId)
  external view
  onlyValidTokenId(_tokenId)
  returns (
    uint256 _editionNumber,
    uint256 _editionType,
    bytes32 _editionData,
    string memory _tokenURI,
    address _owner
  ) {
    uint256 editionNumber = tokenIdToEditionNumber[_tokenId];
    EditionDetails storage editionDetails = editionNumberToEditionDetails[editionNumber];
    return (
    editionNumber,
    editionDetails.editionType,
    editionDetails.editionData,
    tokenURI(_tokenId),
    ownerOf(_tokenId)
    );
  }


  //////////////////////////
  // Edition config query //
  //////////////////////////

  function purchaseDatesEdition(uint256 _editionNumber) public view returns (uint256 _startDate, uint256 _endDate) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return (
    _editionDetails.startDate,
    _editionDetails.endDate
    );
  }

  function artistCommission(uint256 _editionNumber) external view returns (address _artistAccount, uint256 _artistCommission) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return (
    _editionDetails.artistAccount,
    _editionDetails.artistCommission
    );
  }

  function priceInWeiEdition(uint256 _editionNumber) public view returns (uint256 _priceInWei) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.priceInWei;
  }

  function editionActive(uint256 _editionNumber) public view returns (bool) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.active;
  }

  function totalRemaining(uint256 _editionNumber) external view returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.totalAvailable.sub(_editionDetails.totalSupply);
  }

  function totalAvailableEdition(uint256 _editionNumber) public view returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.totalAvailable;
  }

  function totalSupplyEdition(uint256 _editionNumber) public view returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.totalSupply;
  }

  function reclaimEther() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
    if (address(acceptedToken) != address(0)) {
      acceptedToken.transfer(owner(), acceptedToken.balanceOf(address(this)));
    }
  }

}
