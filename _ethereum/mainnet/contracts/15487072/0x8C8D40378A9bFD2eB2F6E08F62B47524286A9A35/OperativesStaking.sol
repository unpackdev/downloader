// SPDX-License-Identifier: MIT
/*
    _   ___ ___    ___                     _   _            
   /_\ |_ _/ __|  / _ \ _ __  ___ _ _ __ _| |_(_)_ _____ ___
  / _ \ | | (__  | (_) | '_ \/ -_) '_/ _` |  _| \ V / -_|_-<
 /_/ \_\___\___|  \___/| .__/\___|_| \__,_|\__|_|\_/\___/__/
                       |_|                                  
                  By Devko.dev#7286
*/
// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: contract.sol

pragma solidity ^0.8.7;

interface IOperatives {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);
}

contract OperativesStaking is Ownable {
    using SafeMath for uint256;

    IOperatives public OperativesContract =
        IOperatives(0x0e64e8432a259C52846AcDaF4E529125E840160f);

    struct token {
        uint256 stakeDate;
        address stakerAddress;
        uint256 tierId;
    }
    mapping(uint256 => token) public stakedTokens;
    mapping(address => uint256) public stakedTokensCount;
    mapping(uint256 => uint256) public tiersDays;

    constructor() {
        tiersDays[1] = 5 days;
        tiersDays[2] = 15 days;
        tiersDays[3] = 30 days;
        tiersDays[4] = 60 days;
    }

    modifier notContract() {
        require(
            (!_isContract(msg.sender)) && (msg.sender == tx.origin),
            "Contracts not allowed"
        );
        _;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function editTier(uint256 tierId, uint256 secondsCount) external onlyOwner {
        tiersDays[tierId] = secondsCount;
    }

    function stake(uint256[] calldata tokenIds, uint256 tierId)
        external
        notContract
    {
        require(tiersDays[tierId] > 0, "TIER_NOT_VALID");

        for (uint256 index = 0; index < tokenIds.length; index++) {
            if (OperativesContract.ownerOf(tokenIds[index]) == msg.sender) {
                OperativesContract.transferFrom(
                    msg.sender,
                    address(this),
                    tokenIds[index]
                );

                stakedTokens[tokenIds[index]].stakeDate = block.timestamp;
                stakedTokens[tokenIds[index]].tierId = tierId;
                stakedTokens[tokenIds[index]].stakerAddress = msg.sender;

                stakedTokensCount[msg.sender]++;
            }
        }
    }

    function unstake(uint256[] calldata tokenIds) external notContract {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            if (
                stakedTokens[tokenIds[index]].stakerAddress == msg.sender &&
                (stakedTokens[tokenIds[index]].stakeDate +
                    tiersDays[stakedTokens[tokenIds[index]].tierId]) <
                block.timestamp
            ) {
                OperativesContract.transferFrom(
                    address(this),
                    msg.sender,
                    tokenIds[index]
                );

                stakedTokens[tokenIds[index]].stakeDate = 0;
                stakedTokens[tokenIds[index]].tierId = 0;
                stakedTokens[tokenIds[index]].stakerAddress = address(0);

                stakedTokensCount[msg.sender]--;
            }
        }
    }

    function tokensDetails(uint256[] memory tokens)
        external
        view
        returns (token[] memory)
    {
        token[] memory tokensList = new token[](tokens.length);

        for (uint256 index = 0; index < tokens.length; index++) {
            tokensList[index] = stakedTokens[tokens[index]];
        }
        return tokensList;
    }

    function tokensOwnedBy(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokensList = new uint256[](
            OperativesContract.balanceOf(owner)
        );
        uint256 currentIndex;
        for (uint256 index = 1; index < 1591; index++) {
            try OperativesContract.ownerOf(index) {
                if (OperativesContract.ownerOf(index) == owner) {
                    tokensList[currentIndex] = uint256(index);
                    currentIndex++;
                }
            } catch {}
        }
        return tokensList;
    }

    function tokensStakedBy(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokensList = new uint256[](stakedTokensCount[owner]);
        uint256 currentIndex = 0;
        for (uint256 tokenId = 1; tokenId < 1591; tokenId++) {
            if (stakedTokens[tokenId].stakerAddress == owner) {
                tokensList[currentIndex] = uint256(tokenId);
                currentIndex++;
            }
        }
        return tokensList;
    }
}