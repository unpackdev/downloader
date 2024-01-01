// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/1_Storage.sol


pragma solidity ^0.8.17;


contract DataStorage is Ownable {
    struct Receipt {
        string ipfsCid;
        uint256 date;
    }

    Receipt[] receipts;
    mapping(uint256 => string[]) private receiptsByDate;

    function addReceipt(string memory _ipfsCid, string memory _date) public onlyOwner {
        uint256 timestamp = parseDate(_date);
        Receipt memory receipt = Receipt(_ipfsCid, timestamp);
        receipts.push(receipt);
        receiptsByDate[timestamp].push(_ipfsCid);
    }

    function parseDate(string memory _date) internal pure returns (uint256) {
        uint256 day = parseInt(substring(_date, 0, 2));
        uint256 month = parseInt(substring(_date, 3, 2));
        uint256 year = parseInt(substring(_date, 6, 4));
        return toTimestamp(year, month, day);
    }

    function parseInt(string memory _value) internal pure returns (uint256) {
    bytes memory _bytesValue = bytes(_value);
    uint256 _number = 0;
    for (uint256 i = 0; i < _bytesValue.length; i++) {
        uint8 _digit = uint8(_bytesValue[i]) - 48;
        require(_digit <= 9, "Invalid digit");
        _number = _number * 10 + _digit;
    }
    return _number;
}


    function substring(string memory _str, uint256 _startIndex, uint256 _length) internal pure returns (string memory) {
        bytes memory _bytesStr = bytes(_str);
        bytes memory _substring = new bytes(_length);
        for (uint256 i = 0; i < _length; i++) {
            _substring[i] = _bytesStr[_startIndex + i];
        }
        return string(_substring);
    }

    function toTimestamp(uint256 _year, uint256 _month, uint256 _day) internal pure returns (uint256) {
        require(_year >= 1970, "Year must be greater than or equal to 1970");
        uint256 _timestamp = 0;
        for (uint256 i = 1970; i < _year; i++) {
            if (isLeapYear(i)) {
                _timestamp += 366 days;
            } else {
                _timestamp += 365 days;
            }
        }
        for (uint256 i = 1; i < _month; i++) {
            if (i == 2) {
                if (isLeapYear(_year)) {
                    _timestamp += 29 days;
                } else {
                    _timestamp += 28 days;
                }
            } else if (i == 4 || i == 6 || i == 9 || i == 11) {
                _timestamp += 30 days;
            } else {
                _timestamp += 31 days;
            }
        }
        _timestamp += (_day - 1) * 1 days;
        return _timestamp;
    }

    function isLeapYear(uint256 _year) internal pure returns (bool) {
        if (_year % 4 != 0) {
            return false;
        }
        if (_year % 100 != 0) {
            return true;
        }
        if (_year % 400 != 0) {
            return false;
        }
        return true;
    }

   function getReceiptsByDate(string memory _date) public view returns (string[] memory) {
        uint256 timestamp = parseDate(_date);
        return receiptsByDate[timestamp];
    }
   function getReceiptsCount() public view returns (uint256) {
        return receipts.length;
}
}