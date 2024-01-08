// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ArtBoxTypes.sol";
import "./ArtBoxUtils.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

/** ArtBox Main contract  */
contract ArtBox is ERC721Enumerable, Ownable {
  /// @dev Events
  event BoxCreated(address indexed owner, uint256 indexed boxId);
  event BoxLocked(
    address indexed owner,
    uint256 indexed boxXId,
    uint256 indexed boxYId
  );
  event BoxUpdated(
    address indexed owner,
    uint256 indexed boxXId,
    uint256 indexed boxYId
  );

  /** @dev Storage */
  uint256 private basePrice;
  uint256 private priceIncreaseFactor;
  uint256 private lockPrice;
  address payable private admin;
  address payable private fundDAO;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  ArtBoxTypes.Box[] private boxesMap;
  mapping(uint256 => mapping(uint256 => ArtBoxTypes.Box)) private boxes;

  /** @dev Constructor function, sets initial price, lock price and factor
   *   @param _admin overrides the administrator of the contract
   *   @param _fundDAO overrides the DAO of the contract
   */
  constructor(address payable _admin, address payable _fundDAO)
    ERC721("ArtBox", "ARTB")
  {
    basePrice = 50000000000000000;
    lockPrice = 500000000000000000;
    priceIncreaseFactor = 100;
    admin = payable(_admin);
    fundDAO = payable(_fundDAO);

    transferOwnership(_admin);
  }

  /** @dev Get current admin address
   *  @return Current admin address
   */
  function getCurrentAdmin() external view returns (address) {
    return admin;
  }

  /** @dev Get current DAO address
   * @return Current DAO address
   */
  function getCurrentFundDAO() external view returns (address) {
    return fundDAO;
  }

  /** @dev Sets the admin to the provider address
   * can only be called by the current owner (admin)
   */
  function updateAdmin(address payable _address) external onlyOwner {
    admin = _address;
    transferOwnership(_address);
  }

  /** @dev Sets the DAO address to the provided address
   * can only be called by the owner (admin)
   */
  function updateFundDAO(address payable _address) external onlyOwner {
    fundDAO = _address;
  }

  /** @dev Get a specific artbox by its coordinates
   * @param _boxXId coordinate for X
   * @param _boxYId coordinate for Y
   * @return ArtBoxTypes.Box an artbox with all the attributes
   */
  function getBoxByCoordinates(uint256 _boxXId, uint256 _boxYId)
    public
    view
    returns (ArtBoxTypes.Box memory)
  {
    return boxes[_boxXId][_boxYId];
  }

  /** @dev Get the full map of artboxes
   * @return Complete array of artboxes.
   */
  function getBoxes() external view returns (ArtBoxTypes.Box[] memory) {
    return boxesMap;
  }

  /** @dev Provides the current price for the next box
   * @return current price for the next box
   */
  function getCurrentPrice() public view returns (uint256) {
    return
      basePrice * ((_tokenIds.current() + 1) * (priceIncreaseFactor / 100));
  }

  /** @dev Get current price to lock a box
   * @return current price to lock a box
   */
  function getCurrentLockPrice() public view returns (uint256) {
    return lockPrice;
  }

  /** @dev Updates the current lock price
   */
  function updateLockPrice(uint256 _newPrice) external onlyOwner {
    lockPrice = _newPrice;
  }

  /** @dev Updates the multiplier used to calculate box prices
   */
  function updateIncreasePriceFactor(uint256 _newFactor) external onlyOwner {
    priceIncreaseFactor = _newFactor;
  }

  /** @dev Generate a new Box with the initial desired state provided by the user
   *  this function is really expensive but does all the work that the contract needs
   *  @param _boxXId the X coordinate of the artbox in the grid
   *  @param _boxYId the Y coordinate of the artbox in the grid
   *  @return the id in the global boxes array
   *  @notice We allocate a maximum of 784 boxes (28x28) to be displayed as one.
   *  @notice increment the total counter so we don't go over 784 boxes
   *  @notice then mint the token and do all the transfers to the admin and the DAO.
   */
  function createBox(
    uint16 _boxXId,
    uint16 _boxYId,
    uint32[16][16] memory boxFields
  ) external payable returns (uint256) {
    uint256 price = getCurrentPrice();
    require(msg.value >= price, "Value not matched");
    require(_boxXId >= 0 && _boxXId <= 28, "There is no room for more boxes");
    require(_boxYId >= 0 && _boxYId <= 28, "There is no room for more boxes");
    require(
      boxes[_boxXId][_boxYId].minter == address(0),
      "The box already exists"
    );

    uint256 newBoxId = _tokenIds.current();
    ArtBoxTypes.Box memory _box = ArtBoxTypes.Box({
      id: newBoxId,
      x: _boxXId,
      y: _boxYId,
      locked: false,
      box: boxFields,
      minter: msg.sender,
      locker: address(0)
    });
    boxes[_boxXId][_boxYId] = _box;
    boxesMap.push(_box);

    require(newBoxId <= 784, "There is no room for more boxes");
    _tokenIds.increment();
    _safeMint(msg.sender, newBoxId);

    admin.transfer(msg.value / 2);
    fundDAO.transfer(address(this).balance);

    // Emit the event and return the box id
    emit BoxCreated(msg.sender, newBoxId);

    return newBoxId;
  }

  /**
   *  @dev We lock the Box forever, it cannot be updated anymore after this
   *  @param boxXId the X coordinate of artbox in the grid
   *  @param boxYId the Y coordinate of artbox in the grid
   *  @return retuns true if the box is now locked
   */
  function lockBox(uint256 boxXId, uint256 boxYId)
    external
    payable
    returns (bool)
  {
    require(
      msg.sender == ownerOf(boxes[boxXId][boxYId].id),
      "Must own the Box"
    );
    require(msg.value == lockPrice, "Must match the price");
    require(boxes[boxXId][boxYId].locked == false, "The box is already locked");

    boxes[boxXId][boxYId].locked = true;

    admin.transfer(msg.value / 2);
    fundDAO.transfer(address(this).balance);

    emit BoxLocked(msg.sender, boxXId, boxYId);

    return boxes[boxXId][boxYId].locked;
  }

  /** @dev Updates the box so the user can have a new shape or color, it has no additional cost.
   *  @param boxXId the X coordinate of artbox in the grid
   *  @param boxYId the Y coordinate of artbox in the grid
   *  @param _box the grid for this artbox to be updated
   * */
  function updateBox(
    uint256 boxXId,
    uint256 boxYId,
    uint32[16][16] memory _box
  ) external {
    require(
      msg.sender == ownerOf(boxes[boxXId][boxYId].id),
      "Must own the Box"
    );
    require(
      boxes[boxXId][boxYId].locked == false,
      "The box cannot be updated anymore"
    );

    boxes[boxXId][boxYId].box = _box;

    for (uint256 i = 0; i <= boxesMap.length; i++) {
      if (boxesMap[i].id == boxes[boxXId][boxYId].id) {
        boxesMap[i].box = _box;
        break;
      }
    }

    emit BoxUpdated(msg.sender, boxXId, boxYId);
  }
}
