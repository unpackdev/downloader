pragma solidity 0.5.2;

/***************
**            **
** INTERFACES **
**            **
***************/

/**
 * @title  Interface for Kong ERC20 Token Contract.
 */
interface KongERC20Interface {

  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function mint(uint256 mintedAmount, address recipient) external;
  function getMintingLimit() external returns(uint256);

}

/**
 * @title Interface for EllipticCurve contract.
 */
interface EllipticCurveInterface {

    function validateSignature(bytes32 message, uint[2] calldata rs, uint[2] calldata Q) external view returns (bool);

}

/****************************
**                         **
** OPEN ZEPPELIN CONTRACTS **
**                         **
****************************/

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**********************************
**                               **
** REGISTER DIRECT MINT CONTRACT **
**                               **
**********************************/

/**
 * @title Register Contract.
 */
contract RegisterDirectMint {
  using SafeMath for uint256;

  // Account with the right to adjust the set of minters.
  address public _owner;

  // Address of the Kong ERC20 account.
  address public _kongERC20Address;

  // Sum of Kong amounts marked as mintable for registered devices.
  uint256 public _totalMintable;

  // Minters.
  mapping (address => bool) public _minters;

  // Minting caps.
  mapping (address => uint256) public _mintingCaps;

  //
  struct Device {
    uint256 kongAmount;
    uint256 mintableTime;
    bool mintable;
  }

  // Registered devices.
  mapping(bytes32 => Device) internal _devices;

  /**
   * @dev Emit when device is registered.
   */
  event Registration(
    bytes32 hardwareHash,
    bytes32 primaryPublicKeyHash,
    bytes32 secondaryPublicKeyHash,
    bytes32 tertiaryPublicKeyHash,
    bytes32 hardwareManufacturer,
    bytes32 hardwareModel,
    bytes32 hardwareSerial,
    bytes32 hardwareConfig,
    uint256 kongAmount,
    uint256 mintableTime,
    bool mintable
  );

  /**
   * @dev Emit when minting rights are delegated / removed.
   */
  event MinterAddition (
    address minter,
    uint256 mintingCap
  );

  event MinterRemoval (
    address minter
  );

  /**
   * @dev Constructor.
   */
  constructor(address owner, address kongAddress) public {

    // Set address of owner.
    _owner = owner;

    // Set address of Kong ERC20 contract.
    _kongERC20Address = kongAddress;

    // Set minting cap of owner account.
    _mintingCaps[_owner] = (2 ** 25 + 2 ** 24 + 2 ** 23 + 2 ** 22) * 10 ** 18;

  }

  /**
   * @dev Throws if called by any account but owner.
   */
  modifier onlyOwner() {
    require(_owner == msg.sender, 'Can only be called by owner.');
    _;
  }

  /**
   * @dev Throws if called by any account but owner or registered minter.
   */
  modifier onlyOwnerOrMinter() {
    require(_owner == msg.sender || _minters[msg.sender] == true, 'Can only be called by owner or minter.');
    _;
  }

  /**
   * @dev Endow `newMinter` with right to add mintable devices up to `mintingCap`.
   */
  function delegateMintingRights(
    address newMinter,
    uint256 mintingCap
  )
    public
    onlyOwner
  {
    // Delegate minting rights.
    _mintingCaps[_owner] = _mintingCaps[_owner].sub(mintingCap);
    _mintingCaps[newMinter] = _mintingCaps[newMinter].add(mintingCap);

    // Add newMinter to dictionary of minters.
    _minters[newMinter] = true;

    // Emit event.
    emit MinterAddition(newMinter, _mintingCaps[newMinter]);
  }

  /**
   * @dev Remove address from the mapping of _minters.
   */
  function removeMintingRights(
    address minter
  )
    public
    onlyOwner
  {
    // Cannot remove rights from _owner.
    require(_owner != minter, 'Cannot remove owner from minters.');

    // Adjust minting rights.
    _mintingCaps[_owner] = _mintingCaps[_owner].add(_mintingCaps[minter]);
    _mintingCaps[minter] = 0;

    // Deactivate minter.
    _minters[minter] = false;

    // Emit event.
    emit MinterRemoval(minter);
  }

  /**
   * @dev Register a new device.
   */
  function registerDevice(
    bytes32 hardwareHash,
    bytes32 primaryPublicKeyHash,
    bytes32 secondaryPublicKeyHash,
    bytes32 tertiaryPublicKeyHash,
    bytes32 hardwareManufacturer,
    bytes32 hardwareModel,
    bytes32 hardwareSerial,
    bytes32 hardwareConfig,
    uint256 kongAmount,
    uint256 mintableTime,
    bool mintable
  )
    public
    onlyOwnerOrMinter
  {
    // Verify that this device has not been registered yet.
    require(_devices[hardwareHash].kongAmount == 0, 'Already registered.');

    // Verify the cumulative limit for mintable Kong has not been exceeded.
    if (mintable) {

      uint256 _maxMinted = KongERC20Interface(_kongERC20Address).getMintingLimit();
      require(_totalMintable.add(kongAmount) <= _maxMinted, 'Exceeds cumulative limit.');

      // Increment _totalMintable.
      _totalMintable += kongAmount;

      // Adjust minting cap. Throws on underflow / Guarantees minter does not exceed its limit.
      _mintingCaps[msg.sender] = _mintingCaps[msg.sender].sub(kongAmount);
    }

    // Create device struct.
    _devices[hardwareHash] = Device(
      kongAmount,
      mintableTime,
      mintable
    );

    // Emit event.
    emit Registration(
      hardwareHash,
      primaryPublicKeyHash,
      secondaryPublicKeyHash,
      tertiaryPublicKeyHash,
      hardwareManufacturer,
      hardwareModel,
      hardwareSerial,
      hardwareConfig,
      kongAmount,
      mintableTime,
      mintable
    );
  }

  /**
   * @dev Mint registered `kongAmount` for `_devices[hardwareHash]` to `recipient`.
   */
  function mintKong(
    bytes32 hardwareHash,
    address recipient
  )
    external
    onlyOwnerOrMinter
  {
    // Get Kong details.
    Device memory d = _devices[hardwareHash];

    // Verify that Kong is mintable.
    require(d.mintable, 'Not mintable / already minted.');
    require(block.timestamp >= d.mintableTime, 'Cannot mint yet.');

    // Set status to minted.
    _devices[hardwareHash].mintable = false;

    // Mint.
    KongERC20Interface(_kongERC20Address).mint(d.kongAmount, recipient);
  }

  /**
   * @dev Return the stored details for a registered device.
   */
  function getRegistrationDetails(
    bytes32 hardwareHash
  )
    external
    view
    returns (uint256, uint256, bool)
  {
    Device memory d = _devices[hardwareHash];

    return (
      d.kongAmount,
      d.mintableTime,
      d.mintable
    );
  }

  /**
   * @dev Return the hashed minting key for a registered device.
   */
  function verifyMintableHardwareHash(
    bytes32 primaryPublicKeyHash,
    bytes32 secondaryPublicKeyHash,
    bytes32 tertiaryPublicKeyHash,
    bytes32 hardwareSerial
  )
    external
    view
    returns (bytes32)
  {
    bytes32 hashedKey = sha256(abi.encodePacked(primaryPublicKeyHash, secondaryPublicKeyHash, tertiaryPublicKeyHash, hardwareSerial));

    Device memory d = _devices[hashedKey];

    require(d.mintable == true, 'Not mintable.');
    require(d.kongAmount > 0, 'No KONG amount to be minted.');

    return hashedKey;
  }

  /**
   * @dev Return Kong amount for a registered device.
   */
  function getKongAmount(
    bytes32 hardwareHash
  )
    external
    view
    returns (uint)
  {
    Device memory d = _devices[hardwareHash];

    return d.kongAmount;
  }

}