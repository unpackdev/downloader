pragma solidity ^0.5.4;// Copyright (C) 2020 LimeChain - Blockchain & DLT Solutions <https://limechain.tech>



/**
 * @title RulesOperator
 * @dev Interface for a IdoneusToken Rules Operator.
 * A Rules Operator must implement the functions below to
 * successfully execute the IdoneusToken approval and transfers
 * functionality.
 */
interface RulesOperator {
    /**
     * @dev Validates upon ERC-20 `approve` call.
     */
    function onApprove(address from, address to, uint256 value)
        external
        returns (bool);

    /**
     * @dev Gets fee amount IdoneusToken owner will take upon ERC-20
     * `transfer` call.
     */
    function onTransfer(address from, address to, uint256 value)
        external
        returns (uint256);

    /**
     * @dev Gets fee amount IdoneusToken owner will take upon ERC-20
     * `transferFrom` call.
     */
    function onTransferFrom(address from, address to, uint256 value)
        external
        returns (uint256);
}


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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
// Copyright (C) 2020 LimeChain - Blockchain & DLT Solutions <https://limechain.tech>



/**
 * @title Operator
 * @dev Simple ownable Operator contract that stores operators.
 */
contract Operator is Ownable {
    // The operators storage
    mapping(address => bool) private operators;

    event OperatorModified(
        address indexed executor,
        address indexed operator,
        bool status
    );

    /**
     * @dev Enables/Disables an operator.
     * @param _operator The target operator.
     * @param _status Set to true to enable an operator.
     */
    function setOperator(address _operator, bool _status) public onlyOwner {
        require(
            _operator != address(0),
            "Operator: operator is the zero address"
        );
        operators[_operator] = _status;
        emit OperatorModified(msg.sender, _operator, _status);
    }

    /**
     * @dev Checks if an operator is enabled/disabled.
     * @param _operator The target operator.
     */
    function isOperator(address _operator) public view returns (bool) {
        return operators[_operator];
    }
}
// Copyright (C) 2020 LimeChain - Blockchain & DLT Solutions <https://limechain.tech>


/**
 * @title Whitelisting
 * @dev Manages whitelisting of accounts (EOA or contracts).
 */
contract Whitelisting is Operator {
    // The whitelisted accounts storage
    mapping(address => bool) private whitelisted;

    event WhitelistedStatusModified(
        address indexed executor,
        address[] user,
        bool status
    );

    /**
     * @dev Throws if the sender is neither operator nor owner.
     */
    modifier onlyAuthorized() {
        require(
            isOperator(msg.sender) || msg.sender == owner(),
            "Whitelisting: the caller is not whitelistOperator or owner"
        );
        _;
    }

    /**
     * @dev Adds/Removes whitelisted accounts.
     * @param _users The target accounts.
     * @param _isWhitelisted Set to true to whitelist accounts.
     */
    function setWhitelisted(address[] memory _users, bool _isWhitelisted)
        public
        onlyAuthorized
    {
        for (uint256 i = 0; i < _users.length; i++) {
            require(
                _users[i] != address(0),
                "Whitelisting: user is the zero address"
            );
            whitelisted[_users[i]] = _isWhitelisted;
        }
        emit WhitelistedStatusModified(msg.sender, _users, _isWhitelisted);
    }

    /**
     * @dev Checks if an account is whitelisted.
     * @param _user The target account.
     */
    function isWhitelisted(address _user) public view returns (bool) {
        return whitelisted[_user];
    }
}


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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// Copyright (C) 2020 LimeChain - Blockchain & DLT Solutions <https://limechain.tech>





/**
 * @title IdonRulesOperator
 * @dev Manages IdoneusToken (IDON) USD price. Used as fee calculator
 * on IDON Token transfers.
 */
contract IdonRulesOperator is RulesOperator, Operator {
    using SafeMath for uint256;

    /**
     * @notice The IDON token price, stored with 3 digits
     * after the decimal point (e.g. $12.340 => 12 340).
     */
    uint256 public idonTokenPrice;

    /**
     * @notice The minimum IDON token price, stored with 3 digits
     * after the decimal point (e.g. $23.456 => 23 456).
     */
    uint256 public minimumIDONPrice;

    /**
     * @notice The transfer fee percentage, stored with 3 digits
     * after the decimal point (e.g. 12.345% => 12 345).
     */
    uint256 public transferFeePercentage;

    // The whitelisting contract storage
    Whitelisting public whitelisting;

    /**
     * @dev Throws if the sender is neither operator nor owner.
     */
    modifier onlyAuthorized() {
        require(
            isOperator(msg.sender) || msg.sender == owner(),
            "RulesOperator: the caller is not Authorised"
        );
        _;
    }

    event TokenPriceModified(address indexed executor, uint256 tokenPrice);
    event FeePercentageModified(
        address indexed executor,
        uint256 feePercentage
    );
    event WhitelistingInstanceModified(
        address indexed executor,
        address whitelisting
    );

    /**
     * @dev Sets the initial values for IDON token price,
     * minimum IDON token price, transfer fee percetange and whitelisting contract.
     *
     * @param _idonTokenPrice Initial IDON token price.
     * @param _minimumIDONPrice Initial minimum IDON token price.
     * @param _transferFeePercentage Initial fee percentage on transfers.
     * @param _whitelisting Initial whitelisting contract.
     */
    constructor(
        uint256 _idonTokenPrice,
        uint256 _minimumIDONPrice,
        uint256 _transferFeePercentage,
        address _whitelisting
    ) public {
        require(
            _idonTokenPrice != 0,
            "IdonRulesOperator: idon token price could not be 0"
        );
        require(
            _transferFeePercentage < 100000,
            "IdonRulesOperator: fee percentage could not be higher than 100%"
        );
        require(
            _whitelisting != address(0),
            "IdonRulesOperator: whitelisting contract address could not be 0"
        );
        idonTokenPrice = _idonTokenPrice;
        minimumIDONPrice = _minimumIDONPrice;
        transferFeePercentage = _transferFeePercentage;
        whitelisting = Whitelisting(_whitelisting);

        emit TokenPriceModified(msg.sender, _idonTokenPrice);
        emit FeePercentageModified(msg.sender, _transferFeePercentage);
        emit WhitelistingInstanceModified(msg.sender, _whitelisting);
    }

    /**
     * @dev Sets IDON Token Price.
     * @param _price The target price.
     */
    function setIdonTokenPrice(uint256 _price) public onlyAuthorized {
        require(
            _price != 0,
            "IdonRulesOperator: idon token price could not be 0"
        );
        idonTokenPrice = _price;
        emit TokenPriceModified(msg.sender, _price);
    }

    /**
     * @dev Sets fee percentage.
     * @param _transferFeePercentage The target transfer fee percentage.
     */
    function setFeePercentage(uint256 _transferFeePercentage) public onlyOwner {
        require(
            _transferFeePercentage < 100000,
            "IdonRulesOperator: fee percentage could not be higher than 100%"
        );
        transferFeePercentage = _transferFeePercentage;
        emit FeePercentageModified(msg.sender, _transferFeePercentage);
    }

    function setWhitelisting(address _whitelisting) public onlyOwner {
        require(
            _whitelisting != address(0),
            "IdonRulesOperator: whitelisting contract address could not be zero address"
        );
        whitelisting = Whitelisting(_whitelisting);
        emit WhitelistingInstanceModified(msg.sender, _whitelisting);
    }

    /**
     * @dev Validates upon IDON token `approve` call.
     * @notice Lacks implementation.
     */
    function onApprove(address from, address to, uint256 value)
        public
        returns (bool)
    {
        return true;
    }

    /**
     * @dev Calculates fee on IDON token `transfer` call.
     * @param from The target sender.
     * @param to The target recipient.
     * @param value The target amount.
     */
    function onTransfer(address from, address to, uint256 value)
        public
        returns (uint256 fee)
    {
        return transactionValidation(from, to, value);
    }

    /**
     * @dev Calculates fee on IDON token `transferFrom` call.
     * @param from The target sender.
     * @param to The target recipient.
     * @param value The target amount.
     */
    function onTransferFrom(address from, address to, uint256 value)
        public
        returns (uint256)
    {
        return transactionValidation(from, to, value);
    }

    /**
     * @dev Calculates fee on IDON Token transfer calls, depending on
     * IDON Token price and the whitelisting of given accounts (EOA or contracts).
     * @param _from The target sender.
     * @param _to The target recipient.
     * @param _value The target amount.
     */
    function transactionValidation(address _from, address _to, uint256 _value)
        internal
        view
        returns (uint256)
    {
        if (idonTokenPrice <= minimumIDONPrice) {
            require(
                whitelisting.isWhitelisted(_from) &&
                    whitelisting.isWhitelisted(_to),
                "IdonRulesOperator: one of the users is not whitelisted"
            );
        }
        if (
            whitelisting.isWhitelisted(_from) && whitelisting.isWhitelisted(_to)
        ) {
            return 0;
        }
        return calculateFee(_value);
    }

    /**
     * @dev Calculates fee of given amount.
     * @notice `transferFeePercentage` is stored with 3 digits
     * after the decimal point (e.g. 12.345% => 12 345).
     * @param _value The target amount
     */
    function calculateFee(uint256 _value) public view returns (uint256) {
        return _value.mul(transferFeePercentage).div(100000);
    }
}
