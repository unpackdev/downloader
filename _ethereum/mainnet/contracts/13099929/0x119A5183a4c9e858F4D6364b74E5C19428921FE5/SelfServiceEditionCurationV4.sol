// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "./Whitelist.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

import "./INRDAV2SelfServiceEditionCuration.sol";
import "./INRDAAuction.sol";
import "./ISelfServiceAccessControls.sol";
import "./ISelfServiceFrequencyControls.sol";
import "./NativeMetaTransaction.sol";

// One invocation per time-period
contract SelfServiceEditionCurationV4 is 
Whitelist, 
Pausable,
NativeMetaTransaction("SelfServiceEditionCurationV4")
{
  function _msgSender()
  internal
  view
  override(Context, NativeMetaTransaction)
  returns (address payable sender) {
    return NativeMetaTransaction._msgSender();
  }

  using SafeMath for uint256;

  event SelfServiceEditionCreated(
    uint256 indexed _editionNumber,
    address indexed _creator,
    uint256 _priceInWei,
    uint256 _totalAvailable,
    bool _enableAuction
  );

  // Calling address
  INRDAV2SelfServiceEditionCuration public nrdaV2;
  INRDAAuction public auction;
  ISelfServiceAccessControls public accessControls;
  ISelfServiceFrequencyControls public frequencyControls;

  // Default NR commission
  uint256 public nrCommission = 15;

  // Config which enforces editions to not be over this size
  uint256 public maxEditionSize = 100;

  // Config the minimum price per edition
  uint256 public minPricePerEdition = 0.01 ether;

  /**
   * @dev Construct a new instance of the contract
   */
  constructor(
    INRDAV2SelfServiceEditionCuration _nrdaV2,
    INRDAAuction _auction,
    ISelfServiceAccessControls _accessControls,
    ISelfServiceFrequencyControls _frequencyControls
  ) public {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    super.addAddressToWhitelist(_msgSender());
    nrdaV2 = _nrdaV2;
    auction = _auction;
    accessControls = _accessControls;
    frequencyControls = _frequencyControls;
  }

  /**
   * @dev Called by artists, create new edition on the NRDA platform
   */
  function createEdition(
    bool _enableAuction,
    address _optionalSplitAddress,
    uint256 _optionalSplitRate,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _artistCommission,
    uint256 _editionType,
    string memory _tokenUri
  )
  public
  whenNotPaused
  returns (uint256 _editionNumber)
  {
    require(frequencyControls.canCreateNewEdition(_msgSender()), 'Sender currently frozen out of creation');
    require(_artistCommission.add(_optionalSplitRate).add(nrCommission) <= 100, "Total commission exceeds 100");

    uint256 editionNumber = _createEdition(
      _msgSender(),
      _enableAuction,
      [_totalAvailable, _priceInWei, _startDate, _endDate, _artistCommission, _editionType],
      _tokenUri
    );

    if (_optionalSplitRate > 0 && _optionalSplitAddress != address(0)) {
      nrdaV2.updateOptionalCommission(editionNumber, _optionalSplitRate, _optionalSplitAddress);
    }

    frequencyControls.recordSuccessfulMint(_msgSender(), _totalAvailable, _priceInWei);

    return editionNumber;
  }

  /**
   * @dev Called by artists, create new edition on the NRDA platform, single commission split between artists and NR only
   */
  function createEditionSimple(
    bool _enableAuction,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _artistCommission,
    uint256 _editionType,
    string memory _tokenUri
  )
  public
  whenNotPaused
  returns (uint256 _editionNumber)
  {
    require(frequencyControls.canCreateNewEdition(_msgSender()), 'Sender currently frozen out of creation');
    require(_artistCommission.add(nrCommission) <= 100, "Total commission exceeds 100");

    uint256 editionNumber = _createEdition(
      _msgSender(),
      _enableAuction,
      [_totalAvailable, _priceInWei, _startDate, _endDate, _artistCommission, _editionType],
      _tokenUri
    );

    frequencyControls.recordSuccessfulMint(_msgSender(), _totalAvailable, _priceInWei);

    return editionNumber;
  }

  /**
   * @dev Caller by owner, can create editions for other artists
   * @dev Only callable from owner regardless of pause state
   */
  function createEditionFor(
    address _artist,
    bool _enableAuction,
    address _optionalSplitAddress,
    uint256 _optionalSplitRate,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _artistCommission,
    uint256 _editionType,
    string memory _tokenUri
  )
  public
  onlyIfWhitelisted(_msgSender())
  returns (uint256 _editionNumber)
  {
    require(_artistCommission.add(_optionalSplitRate).add(nrCommission) <= 100, "Total commission exceeds 100");

    uint256 editionNumber = _createEdition(
      _artist,
      _enableAuction,
      [_totalAvailable, _priceInWei, _startDate, _endDate, _artistCommission, _editionType],
      _tokenUri
    );

    if (_optionalSplitRate > 0 && _optionalSplitAddress != address(0)) {
      nrdaV2.updateOptionalCommission(editionNumber, _optionalSplitRate, _optionalSplitAddress);
    }

    frequencyControls.recordSuccessfulMint(_artist, _totalAvailable, _priceInWei);

    return editionNumber;
  }

  /**
   * @dev Internal function for edition creation
   */
  function _createEdition(
    address _artist,
    bool _enableAuction,
    uint256[6] memory _params,
    string memory _tokenUri
  )
  internal
  returns (uint256 _editionNumber) {

    uint256 _totalAvailable = _params[0];
    uint256 _priceInWei = _params[1];

    // Enforce edition size
    require(_msgSender() == owner() || (_totalAvailable > 0 && _totalAvailable <= maxEditionSize), "Invalid edition size");

    // Enforce min price
    require(_msgSender() == owner() || _priceInWei >= minPricePerEdition, "Invalid price");

    // If we are the owner, skip this artists check
    require(_msgSender() == owner() || accessControls.isEnabledForAccount(_artist), "Not allowed to create edition");

    // Find the next edition number we can use
    uint256 editionNumber = getNextAvailableEditionNumber();

    require(
      nrdaV2.createEdition(
        editionNumber,
        0x0, // _editionData - no edition data
        _params[5], //_editionType,
        _params[2], // _startDate,
        _params[3], //_endDate,
        _artist,
        _params[4], // _artistCommission - defaults to artistCommission if optional commission split missing
        _priceInWei,
        _tokenUri,
        _totalAvailable,
        true
      ),
      "Failed to create new edition"
    );

    // Enable the auction if desired
    if (_enableAuction) {
      auction.setArtistsControlAddressAndEnabledEdition(editionNumber, _artist);
    }

    // Trigger event
    emit SelfServiceEditionCreated(editionNumber, _artist, _priceInWei, _totalAvailable, _enableAuction);

    return editionNumber;
  }

  /**
   * @dev Internal function for dynamically generating the next NRDA edition number
   */
  function getNextAvailableEditionNumber() internal returns (uint256 editionNumber) {

    // Get current highest edition and total in the edition
    uint256 highestEditionNumber = nrdaV2.highestEditionNumber();
    uint256 totalAvailableEdition = nrdaV2.totalAvailableEdition(highestEditionNumber);

    // Add the current highest plus its total, plus 1 as tokens start at 1 not zero
    uint256 nextAvailableEditionNumber = highestEditionNumber.add(totalAvailableEdition).add(1);

    // Round up to next 100, 1000 etc based on max allowed size
    return ((nextAvailableEditionNumber + maxEditionSize - 1) / maxEditionSize) * maxEditionSize;
  }

  /**
   * @dev Sets the NRDA address
   * @dev Only callable from owner
   */
  function setNrdavV2(INRDAV2SelfServiceEditionCuration _nrdaV2) onlyIfWhitelisted(_msgSender()) public {
    nrdaV2 = _nrdaV2;
  }

  /**
   * @dev Sets the NRDA auction
   * @dev Only callable from owner
   */
  function setAuction(INRDAAuction _auction) onlyIfWhitelisted(_msgSender()) public {
    auction = _auction;
  }

  /**
   * @dev Sets the default NR commission for each edition
   * @dev Only callable from owner
   */
  function setNrCommission(uint256 _nrCommission) onlyIfWhitelisted(_msgSender()) public {
    nrCommission = _nrCommission;
  }

  /**
   * @dev Sets the max edition size
   * @dev Only callable from owner
   */
  function setMaxEditionSize(uint256 _maxEditionSize) onlyIfWhitelisted(_msgSender()) public {
    maxEditionSize = _maxEditionSize;
  }

  /**
   * @dev Sets minimum price per edition
   * @dev Only callable from owner
   */
  function setMinPricePerEdition(uint256 _minPricePerEdition) onlyIfWhitelisted(_msgSender()) public {
    minPricePerEdition = _minPricePerEdition;
  }

  /**
   * @dev Checks to see if the account is currently frozen out
   */
  function isFrozen(address account) public view returns (bool) {
    return frequencyControls.canCreateNewEdition(account);
  }

  /**
   * @dev Checks to see if the account can create editions
   */
  function isEnabledForAccount(address account) public view returns (bool) {
    return accessControls.isEnabledForAccount(account);
  }

  /**
   * @dev Checks to see if the account can create editions
   */
  function canCreateAnotherEdition(address account) public view returns (bool) {
    if (!accessControls.isEnabledForAccount(account)) {
      return false;
    }
    return frequencyControls.canCreateNewEdition(account);
  }

  /**
   * @dev Allows for the ability to extract stuck ether
   * @dev Only callable from owner
   */
  function withdrawStuckEther(address _withdrawalAccount) onlyIfWhitelisted(_msgSender()) public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    payable(_withdrawalAccount).transfer(address(this).balance);
  }
}
