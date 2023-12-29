pragma solidity 0.5.17;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library LibAddressList {

    struct List {
        // max limit of address added to list
        uint256 limit;
        address[] addressList;
        mapping (address => bool) addresses;
    }

    /// @dev Get if an addresses is in list
    function has(List storage list, address _address) internal view returns (bool) {
        return list.addresses[_address];
    }

    /// @dev Get all addresses in list
    function all(List storage list) internal view returns (address[] memory) {
        return list.addressList;
    }

    /// @dev add Address into list
    /// @param list Storage of list
    /// @param _address Address to add
    function add(List storage list, address _address) internal {
        require(!list.addresses[_address], "duplicated");
        require(list.addressList.length < list.limit, "full");

        list.addresses[_address] = true;
        list.addressList.push(_address);
    }

    /// @dev remove Address from list
    /// @param list Storage of list
    /// @param _address Address to add
    function remove(List storage list, address _address) internal {
        require(list.addresses[_address], "not exist");

        delete list.addresses[_address];
        for (uint i = 0; i < list.addressList.length; i++){
            if(list.addressList[i] == _address) {
                list.addressList[i] = list.addressList[list.addressList.length - 1];
                list.addressList.length -= 1;
                break;
            }
        }
    }
}

library LibMathUnsigned {
    uint256 private constant _WAD = 10**18;
    uint256 private constant _UINT256_MAX = 2**255 - 1;

    function WAD() internal pure returns (uint256) {
        return _WAD;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Unaddition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Unsubtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Unmultiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "Undivision by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), _WAD / 2) / _WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, _WAD), y / 2) / y;
    }

    function wfrac(uint256 x, uint256 y, uint256 z) internal pure returns (uint256 r) {
        r = mul(x, y) / z;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function toInt256(uint256 x) internal pure returns (int256) {
        require(x <= _UINT256_MAX, "uint256 overflow");
        return int256(x);
    }

    function mod(uint256 x, uint256 m) internal pure returns (uint256) {
        require(m != 0, "mod by zero");
        return x % m;
    }

    function ceil(uint256 x, uint256 m) internal pure returns (uint256) {
        require(m > 0, "ceil need m > 0");
        return (sub(add(x, m), 1) / m) * m;
    }
}

// see https://github.com/makerdao/median/blob/master/src/median.sol
interface IMakerMedianFeeder {
    function peek() external view returns (uint256, bool);

    function read() external view returns (uint256);

    function age() external view returns (uint32);
}

contract MakerMedianAdapter is Ownable {
    using LibMathUnsigned for uint256;
    using LibAddressList for LibAddressList.List;

    IMakerMedianFeeder public feeder;
    uint256 public decimals;
    uint256 public converter;
    LibAddressList.List private whitelist;

    event AddWhitelisted(address indexed guy);
    event RemoveWhitelisted(address indexed guy);

    constructor(address _feeder, uint256 _decimals, uint256 _limit) public {
        feeder = IMakerMedianFeeder(_feeder);
        setDecimals(_decimals);
        whitelist.limit = _limit;
    }

    function setDecimals(uint256 _decimals) public onlyOwner {
        require(_decimals <= 18, "unsupported decimals");
        decimals = _decimals;
        converter = 10 ** (18 - _decimals);
    }

    function addWhitelisted(address guy) public onlyOwner {
        whitelist.add(guy);
        emit AddWhitelisted(guy);
    }

    function removeWhitelisted(address guy) public onlyOwner {
        whitelist.remove(guy);
        emit RemoveWhitelisted(guy);
    }

    function isWhitelisted(address guy) public view returns (bool) {
        return whitelist.has(guy);
    }

    function allWhitelisted() public view returns (address[] memory) {
        return whitelist.all();
    }

    function price() public view returns (uint256 newPrice, uint256 newTimestamp) {
        require(whitelist.has(msg.sender), "not whitelisted");
        newPrice = feeder.read().mul(converter);
        newTimestamp = uint256(feeder.age());
    }
}