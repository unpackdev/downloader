pragma solidity 0.4.25;

library StringUtil {
  struct slice {
    uint _length;
    uint _pointer;
  }

  function validateUserName(string memory _username)
  internal
  pure
  returns (bool)
  {
    uint8 len = uint8(bytes(_username).length);
    if ((len < 4) || (len > 18)) return false;

    // only contain A-Z 0-9
    for (uint8 i = 0; i < len; i++) {
      if (
        (uint8(bytes(_username)[i]) < 48) ||
        (uint8(bytes(_username)[i]) > 57 && uint8(bytes(_username)[i]) < 65) ||
        (uint8(bytes(_username)[i]) > 90)
      ) return false;
    }
    // First char != '0'
    return uint8(bytes(_username)[0]) != 48;
  }
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


library UnitConverter {
  using SafeMath for uint256;

  function stringToBytes24(string memory source)
  internal
  pure
  returns (bytes24 result)
  {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      result := mload(add(source, 24))
    }
  }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
contract IUSDT {
    function transfer(address to, uint256 value) public;

    function approve(address spender, uint256 value) public;

    function transferFrom(address from, address to, uint256 value) public;

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Auth {

  address internal mainAdmin;
  address internal backupAdmin;
  address internal contractAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor(
    address _mainAdmin,
    address _backupAdmin,
    address _contractAdmin
  ) internal {
    mainAdmin = _mainAdmin;
    backupAdmin = _backupAdmin;
    contractAdmin = _contractAdmin;
  }

  modifier onlyMainAdmin() {
    require(isMainAdmin(), 'onlyMainAdmin');
    _;
  }

  modifier onlyBackupAdmin() {
    require(isBackupAdmin(), 'onlyBackupAdmin');
    _;
  }

  modifier onlyContractAdmin() {
    require(isContractAdmin() || isMainAdmin(), 'onlyContractAdmin');
    _;
  }

  function transferOwnership(address _newOwner) onlyBackupAdmin internal {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }

  function isBackupAdmin() public view returns (bool) {
    return msg.sender == backupAdmin;
  }

  function isContractAdmin() public view returns (bool) {
    return msg.sender == contractAdmin;
  }
}





contract Exchange is Auth {
  using StringUtil for string;
  using UnitConverter for string;

  struct Order {
    string id;
    address maker;
    address taker;
    uint amount; // decimal 3
    uint price; // decimal 3
  }

  mapping (string => Order) orders;
  IUSDT usdtToken = IUSDT(0xdAC17F958D2ee523a2206206994597C13D831ec7);

  event OrderMade(string id, address indexed maker, uint amount, uint price, uint timestamp);
  event OrderCanceled(string id, uint timestamp);
  event OrderCanceledByAdmin(string id, uint timestamp);
  event OrderTaken(string id, address indexed taker, uint timestamp);
  event Withdrew(address indexed user, uint amount, uint timestamp);
  event WithdrewCanceled(address indexed user, string id, uint timestamp);

  constructor (
    address _mainAdmin,
    address _backupAdmin
  )
  Auth(_mainAdmin, _backupAdmin, msg.sender)
  public {}

  function updateMainAdmin(address _admin) public {
    transferOwnership(_admin);
  }

  function updateBackupAdmin(address _backupAdmin) onlyBackupAdmin public {
    require(_backupAdmin != address(0x0), 'Invalid address');
    backupAdmin = _backupAdmin;
  }

  function updateContractAdmin(address _contractAdmin) onlyMainAdmin public {
    require(_contractAdmin != address(0x0), 'Invalid address');
    contractAdmin = _contractAdmin;
  }

  function adminCancelOrder(string _id) onlyContractAdmin public {
    delete orders[_id];
    emit OrderCanceledByAdmin(_id, now);
  }

  function makeOrder(string _id, uint _amount, uint _price) public {
    require(orders[_id].maker == address(0x0), 'Duplicate id!!!');
    require(bytes(_id).length > 0, 'Invalid id');
    require(_price > 0 && _price < 10000, 'Invalid price!!!');
    orders[_id] = Order (
      _id,
      msg.sender,
      address(0x0),
      _amount,
      _price
    );
    emit OrderMade(_id, msg.sender, _amount, _price, now);
  }

  function cancelOrder(string _id) public {
    require(orders[_id].maker == msg.sender, 'This order is not belong to you!!!');
    require(orders[_id].taker == address(0x0), 'You can not cancel an taken order!!!');
    delete orders[_id];
    emit OrderCanceled(_id, now);
  }

  function takeOrder(string _id) public {
    Order storage order = orders[_id];
    require(order.maker != address(0x0), 'Order not found!!!');
    require(order.taker == address(0x0), 'Order taken!!!');
    require(order.maker != msg.sender, 'Can not buy your order!!!');
    uint tokenAmount = order.amount * order.price;
    usdtToken.transferFrom(msg.sender, order.maker, tokenAmount);
    orders[_id].taker = msg.sender;
    emit OrderTaken(_id, msg.sender, now);
  }

  function withdraw(uint amount) public {
    emit Withdrew(msg.sender, amount, now);
  }

  function cancelWithdraw(string id) public {
    emit WithdrewCanceled(msg.sender, id, now);
  }
}