// File: projects/marketplace/libs/Shuffler.sol


// Copyright (c) 2023 Fellowship

pragma solidity ^0.8.7;

/// @notice A contract that draws (without replacement) pseudorandom shuffled values
/// @dev Uses prevrandao and Fisher-Yates shuffle to return values one at a time
contract Shuffler {
    uint256 internal remainingValueCount;
    /// @notice Mapping that lets `drawNext` find values that are still available
    /// @dev This is effectively the Fisher-Yates in-place array. Zero values stand in for their key to avoid costly
    ///  initialization. All other values are off-by-one so that zero can be represented. Keys from remainingValueCount
    ///  onward have their values set back to zero since they aren't needed once they've been drawn.
    mapping(uint256 => uint256) private shuffleValues;

    constructor(uint256 shuffleSize) {
        // CHECKS
        require(shuffleSize <= type(uint16).max, "Shuffle size is too large");

        // EFFECTS
        remainingValueCount = shuffleSize;
    }

    function drawNext() internal returns (uint256) {
        require(remainingValueCount > 0, "Shuffled values have been exhausted");

        uint256 swapValue = shuffleValues[remainingValueCount - 1];
        if (swapValue == 0) {
            swapValue = remainingValueCount;
        } else {
            shuffleValues[remainingValueCount - 1] = 0;
        }

        if (remainingValueCount == 1) {
            // swapValue is the last value left; just return it
            remainingValueCount = 0;
            return swapValue; // Changed for 1-indexing
        }

        uint256 randomIndex = uint256(keccak256(abi.encodePacked(remainingValueCount, block.difficulty))) %
            remainingValueCount;
        unchecked {
            // Unchecked arithmetic: remainingValueCount is nonzero
            remainingValueCount--;
            // Check if swapValue was drawn
            // Unchecked arithmetic: swapValue is nonzero
            if (randomIndex == remainingValueCount) return swapValue; // Changed for 1-indexing
        }

        // Draw the value at randomIndex and put swapValue in its place
        uint256 drawnValue = shuffleValues[randomIndex];
        shuffleValues[randomIndex] = swapValue;

        unchecked {
            // Unchecked arithmetic: only subtract if drawnValue is nonzero
            return drawnValue > 0 ? drawnValue : randomIndex + 1; // Changed for 1-indexing
        }
    }

    function drawSpecific(uint256 id) internal returns (bool) {

        // Adjust for 1-indexing, subtract 1 from id
        id--;

        // The value at 'id' is either its own index or already swapped with another index
        // Since we know it's not drawn, we just swap it with the last index and decrease the count.
        uint256 swapValue = shuffleValues[remainingValueCount - 1];
        if (swapValue == 0) {
            swapValue = remainingValueCount;
        } else {
            shuffleValues[remainingValueCount - 1] = 0;
        }

        // Perform the swap and decrease the remainingValueCount
        shuffleValues[id] = swapValue;
        remainingValueCount--;

        return true;
    }
}
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: projects/marketplace/libs/EarlyAccessSale.sol


// Copyright (c) 2022 - 2023 Fellowship

pragma solidity ^0.8.7;



abstract contract PatronPass is IERC721 {
    function logPassUse(uint256 tokenId, uint256 projectId) external virtual;

    function passUses(uint256 tokenId, uint256 projectId) external view virtual returns (uint256);

    function projectInfo(uint256 projectId) external view virtual returns (address, address, string memory);
}

contract EarlyAccessSale is Ownable {
    /// @notice Timestamp when this auction starts allowing minting
    uint256 public startTime;

    /// @notice Duration of the early access period where minting is limited to pass holders
    uint256 public earlyAccessDuration;

    /// @notice The contract that is used to gate minting during the early access period
    PatronPass public passes;

    /// @notice The project id for this auction in `passes`
    uint256 internal passProjectId;

    /// @notice Whether or not this contract is paused
    /// @dev The exact meaning of "paused" will vary by contract, but in general paused contracts should prevent most
    ///  interactions from non-owners
    bool public isPaused = false;
    uint256 private pauseStart;
    uint256 internal pastPauseDelay;

    event Paused();
    event Unpaused();

    /// @notice An error returned when the auction has already started
    error AlreadyStarted();
    /// @notice An error returned when the auction has not yet started
    error NotYetStarted();

    /// @notice An error returned when minting during early access without a pass
    error EarlyAccessWithoutPass();

    error ContractIsPaused();
    error ContractNotPaused();

    constructor(uint256 startTime_, uint256 earlyAccessDuration_) {
        // CHECKS inputs
        require(startTime_ >= block.timestamp, "Start time cannot be in the past");
        //require(earlyAccessDuration_ >= 60 * 5, "Early access must last at least 5 minutes");
        require(earlyAccessDuration_ <= 60 * 60 * 24, "Early access must not last longer than 24 hours");

        // EFFECTS
        startTime = startTime_;
        earlyAccessDuration = earlyAccessDuration_;
    }

    modifier started() {
        if (!isStarted()) revert NotYetStarted();
        _;
    }
    modifier unstarted() {
        if (isStarted()) revert AlreadyStarted();
        _;
    }

    modifier publicMint() {
        if (!isPublic()) revert EarlyAccessWithoutPass();
        _;
    }

    modifier whenPaused() {
        if (!isPaused) revert ContractNotPaused();
        _;
    }

    modifier whenNotPaused() {
        if (isPaused) revert ContractIsPaused();
        _;
    }

    // OWNER FUNCTIONS

    /// @notice Pause this contract
    /// @dev Can only be called by the contract `owner`
    function pause() public virtual whenNotPaused onlyOwner {
        // EFFECTS (checks already handled by modifiers)
        isPaused = true;
        pauseStart = block.timestamp;
        emit Paused();
    }

    /// @notice Resume this contract
    /// @dev Can only be called by the contract `owner`
    function unpause() public virtual whenPaused onlyOwner {
        // EFFECTS (checks already handled by modifiers)
        isPaused = false;
        emit Unpaused();

        // See if pastPauseDelay needs updated
        if (block.timestamp <= startTime) {
            return;
        }
        // Find the amount time the auction should have been live, but was paused
        unchecked {
            // Unchecked arithmetic: computed value will be < block.timestamp and >= 0
            if (pauseStart < startTime) {
                pastPauseDelay = block.timestamp - startTime;
            } else {
                pastPauseDelay += (block.timestamp - pauseStart);
            }
        }
    }

    /// @notice Update the auction start time
    /// @dev Can only be called by the contract `owner`. Reverts if the auction has already started.
    function setStartTime(uint256 startTime_) external unstarted onlyOwner {
        // CHECKS inputs
        require(startTime_ >= block.timestamp, "New start time cannot be in the past");
        // EFFECTS
        startTime = startTime_;
    }

    /// @notice Update the duration of the early access period
    /// @dev Can only be called by the contract `owner`. Reverts if the auction has already started.
    function setEarlyAccessDuration(uint256 duration) external unstarted onlyOwner {
        // CHECKS inputs
        //require(duration >= 60 * 1, "Early access must last at least 1 minute");
        require(duration <= 60 * 60 * 24, "Early access must not last longer than 24 hours");

        // EFFECTS
        earlyAccessDuration = duration;
    }

    /// @notice Update the pass contract for the early access period
    /// @dev Can only be called by the contract `owner`. Reverts if the auction has already started.
    function setPassContract(PatronPass passContract, uint256 projectId) external unstarted onlyOwner {
        // CHECKS inputs
        (address projectMinter, , ) = passContract.projectInfo(projectId);
        require(projectMinter == address(this), "Specified pass project is not configured for this auction");

        // EFFECTS
        passes = passContract;
        passProjectId = projectId;

        if (isStarted()) {
            // If setting the contract started the auction, then we need to pretend we were paused up to this point
            unchecked {
                // Unchecked arithmetic: startTime <= block.timestamp because the auction has started
                pastPauseDelay = block.timestamp - startTime;
            }
        }
    }

    // VIEW FUNCTIONS

    /// @notice Query if the early access period has ended
    function isPublic() public view returns (bool) {
        return isStarted() && block.timestamp >= (startTime + pastPauseDelay + earlyAccessDuration);
    }

    /// @notice Query if this contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` if `interfaceID` is implemented and is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x7f5828d0 || // ERC-173 Contract Ownership Standard
            interfaceId == 0x01ffc9a7; // ERC-165 Standard Interface Detection
    }

    // INTERNAL FUNCTIONS

    function isStarted() internal view virtual returns (bool) {
        return address(passes) != address(0) && (isPaused ? pauseStart : block.timestamp) >= startTime;
    }

    function timeElapsed() internal view returns (uint256) {
        if (!isStarted()) return 0;
        unchecked {
            // pastPauseDelay cannot be greater than the time passed since startTime
            if (!isPaused) {
                return block.timestamp - startTime - pastPauseDelay;
            }

            // pastPauseDelay cannot be greater than the time between startTime and pauseStart
            return pauseStart - startTime - pastPauseDelay;
        }
    }
}
// File: projects/marketplace/libs/Delegation.sol


// Copyright (c) 2023 Fellowship

pragma solidity ^0.8.7;


interface IDelegationRegistry {
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

library Delegation {
    IDelegationRegistry public constant DELEGATION_REGISTRY =
        IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    function check(address operator, IERC721 contract_, uint256 tokenId) internal view returns (bool) {
        address owner = contract_.ownerOf(tokenId);
        return (operator == owner ||
            contract_.isApprovedForAll(owner, operator) ||
            contract_.getApproved(tokenId) == operator ||
            (address(DELEGATION_REGISTRY).code.length > 0 &&
                DELEGATION_REGISTRY.checkDelegateForToken(operator, owner, address(contract_), tokenId)));
    }
}
// File: @openzeppelin/contracts/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;



/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File: projects/marketplace/fp_ad_marketplace-p4.sol


// Copyright (c) 2022-2023 Fellowship

pragma solidity ^0.8.7;






struct AuctionStage {
    /// @notice Amount that the price drops (in wei) every slot (every 12 seconds)
    uint256 priceDropPerSlot;
    /// @notice Price where this auction stage ends (in wei)
    uint256 endPrice;
    /// @notice The duration of time that this stage will last, in seconds
    uint256 duration;
}

struct AuctionStageConfiguration {
    /// @notice Amount that the price drops (in wei) every slot (every 12 seconds)
    uint256 priceDropPerSlot;
    /// @notice Price where this auction stage ends (in wei)
    uint256 endPrice;
}

contract FellowshipDutchAuction is EarlyAccessSale, Shuffler {
    string private publicLimitRevertMessage;

    /// @notice The number of mints available for each pass
    uint256 public passLimit;

    /// @notice The number of mints available without a pass (per address), after the early access period
    uint256 public publicLimit;

    /// @notice The total number of mints available until the auction is sold out
    uint256 public mintLimit;

    /// @notice ERC-721 contract whose tokens are minted by this auction
    /// @dev Must implement MintableById and allow minting out of order
    address public tokenContract;

    /// @notice Starting price for the Dutch auction (in wei)
    uint256 public startPrice;

    /// @notice Lowest price at which a token was minted (in wei)
    uint256 public lowestPrice;

    /// @notice Stages for this auction, in order
    AuctionStage[] public auctionStages;

    /// @notice Number of reserveTokens that have been minted
    uint256 public reserveCount = 0;

    /// @notice Number of tokens that have been minted per address
    mapping(address => uint256) public mintCount;
    /// @notice Total amount paid to mint per address
    mapping(address => uint256) public mintPayment;

    /// @notice Number of tokens that have been minted without a pass, per address
    /// @dev May over count public mints on the final sale transaction, so not publicly exposed
    mapping(address => uint256) private publicMintCount;

    uint256 private previousPayment = 0;

    /// @notice An event emitted upon purchases
    event Purchase(address purchaser, uint256 mintId, uint256 tokenId, uint256 price, bool passMint);

    /// @notice An event emitted when reserve tokens are minted
    event Reservation(address recipient, uint256 quantity, uint256 totalReserved);

    /// @notice An event emitted when a refund is sent to a minter
    event Refund(address recipient, uint256 amount);

    /// @notice An error returned when the auction has reached its `mintLimit`
    error SoldOut();

    error FailedWithdraw(uint256 amount, bytes data);

    constructor(
        address tokenContract_,
        uint256 startTime_,
        uint256 startPrice_,
        uint256 earlyPriceDrop,
        uint256 transitionPrice,
        uint256 latePriceDrop,
        uint256 restPrice,
        uint256 mintLimit_,
        uint256 publicLimit_,
        uint256 passLimit_,
        uint256 earlyAccessDuration_
    ) EarlyAccessSale(startTime_, earlyAccessDuration_) Shuffler(mintLimit_) {
        // CHECKS inputs
        require(address(tokenContract_) != address(0), "Token contract must not be the zero address");

        require(restPrice > 1e15, "Rest price too low: check that prices are in wei");
        require(startPrice_ >= transitionPrice, "Start price must not be lower than transition price");
        require(transitionPrice >= restPrice, "Transition price must not be lower than rest price");

        uint256 earlyPriceDifference;
        uint256 latePriceDifference;
        unchecked {
            earlyPriceDifference = startPrice_ - transitionPrice;
            latePriceDifference = transitionPrice - restPrice;
        }
        require(earlyPriceDrop * 25 <= earlyPriceDifference, "Initial stage must last at least 5 minutes");
        require(latePriceDrop * 25 <= latePriceDifference, "Final stage must last at least 5 minutes");
        require(earlyPriceDifference % earlyPriceDrop == 0, "Transition price must be reachable by earlyPriceDrop");
        require(latePriceDifference % latePriceDrop == 0, "Resting price must be reachable by latePriceDrop");
        require(
            earlyPriceDrop * (5 * 60 * 12) >= earlyPriceDifference,
            "Initial stage must not last longer than 12 hours"
        );
        require(latePriceDrop * (5 * 60 * 12) >= latePriceDifference, "Final stage must not last longer than 12 hours");

        require(mintLimit_ >= 10, "Mint limit too low");
        require(passLimit_ != 0, "Pass limit must not be zero");
        require(publicLimit_ != 0, "Public limit must not be zero");
        require(passLimit_ < mintLimit_, "Pass limit must be lower than mint limit");
        require(publicLimit_ < mintLimit_, "Public limit must be lower than mint limit");

        // EFFECTS
        tokenContract = tokenContract_;
        lowestPrice = startPrice = startPrice_;

        unchecked {
            AuctionStage storage earlyStage = auctionStages.push();
            earlyStage.priceDropPerSlot = earlyPriceDrop;
            earlyStage.endPrice = transitionPrice;
            earlyStage.duration = (12 * earlyPriceDifference) / earlyPriceDrop;

            AuctionStage storage lateStage = auctionStages.push();
            lateStage.priceDropPerSlot = latePriceDrop;
            lateStage.endPrice = restPrice;
            lateStage.duration = (12 * latePriceDifference) / latePriceDrop;
        }

        mintLimit = mintLimit_;
        passLimit = passLimit_;
        publicLimit = publicLimit_;

        publicLimitRevertMessage = publicLimit_ == 1
            ? "Limited to one purchase without a pass"
            : string.concat("Limited to ", Strings.toString(publicLimit_), " purchases without a pass");
    }

    // PUBLIC FUNCTIONS

    /// @notice Mint a token on the `tokenContract` contract. Must include at least `currentPrice`.
    function mint() external payable publicMint {
        // CHECKS
        require(publicMintCount[msg.sender] < publicLimit, publicLimitRevertMessage);

        // EFFECTS
        unchecked {
            // Unchecked arithmetic: publicMintCount cannot exceed publicLimit
            publicMintCount[msg.sender]++;
        }

        // Proceed to core mint logic (including all CHECKS + EFFECTS + INTERACTIONS)
        _mint(false);
    }

    /// @notice Mint multiple tokens on the `tokenContract` contract. Must pay at least `currentPrice` * `quantity`.
    /// @param quantity The number of tokens to mint: must not be greater than `publicLimit`
    function mintMultiple(uint256 quantity) public payable virtual publicMint whenNotPaused {
        // CHECKS state and inputs
        uint256 remaining = remainingValueCount;
        if (remaining == 0) revert SoldOut();
        uint256 alreadyMinted = mintCount[msg.sender];
        require(quantity > 0, "Must mint at least one token");

        uint256 publicMinted = publicMintCount[msg.sender];
        require(publicMinted < publicLimit && quantity <= publicLimit, publicLimitRevertMessage);

        uint256 price = msg.value / quantity;
        uint256 slotPrice = currentPrice();
        require(price >= slotPrice, "Insufficient payment");

        // EFFECTS
        if (quantity > remaining) {
            quantity = remaining;
        }

        unchecked {
            if (publicMinted + quantity > publicLimit) {
                quantity = publicLimit - publicMinted;
            }

            // Unchecked arithmetic: mintCount cannot exceed mintLimit
            mintCount[msg.sender] = alreadyMinted + quantity;
            // Unchecked arithmetic: publicMintCount cannot exceed publicLimit
            publicMintCount[msg.sender] += quantity;
            // Unchecked arithmetic: can't exceed total existing wei; not expected to exceed mintLimit * startPrice
            mintPayment[msg.sender] += msg.value;
        }

        if (slotPrice < lowestPrice) {
            lowestPrice = slotPrice;
        }

        // INTERACTIONS: call mint on known contract (tokenContract.mint contains no external interactions)
        unchecked {
            uint256 startMintId = mintLimit - remainingValueCount;
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = drawNext();
                emit Purchase(msg.sender, startMintId + i, tokenId, price, false);        
                try INFT(tokenContract).ownerOf(tokenId) returns (address _owner) {
                    if (_owner == address(0)){
                        INFT(tokenContract).mint(msg.sender, tokenId);
                    } else {
                        INFT(tokenContract).transferFrom(_owner, msg.sender, tokenId);
                    }
                }
                catch {
                    INFT(tokenContract).mint(msg.sender, tokenId);
                }
            }
        }
    }

    /// @notice Send any available refund to the message sender
    function refund() external returns (uint256) {
        // CHECK available refund
        uint256 refundAmount = refundAvailable(msg.sender);
        require(refundAmount > 0, "No refund available");

        // EFFECTS
        unchecked {
            // Unchecked arithmetic: refundAmount will always be less than mintPayment
            mintPayment[msg.sender] -= refundAmount;
        }

        emit Refund(msg.sender, refundAmount);

        // INTERACTIONS
        (bool refunded, ) = msg.sender.call{value: refundAmount}("");
        require(refunded, "Refund transfer was reverted");

        return refundAmount;
    }

    // PASS HOLDER FUNCTIONS

    /// @notice Mint a token on the `tokenContract` to the caller, using a pass
    /// @param passId The pass token ID: caller must be owner or operator and pass must have at least one mint remaining
    function mintFromPass(uint256 passId) external payable started {
        // CHECKS that the caller has permissions and the pass can be used
        require(passAllowance(passId) > 0, "No mints remaining for provided pass");

        // INTERACTIONS: mark the pass as used (known contract with no external interactions)
        passes.logPassUse(passId, passProjectId);

        // Proceed to core mint logic (including all CHECKS + EFFECTS + INTERACTIONS)
        _mint(true);
    }

    /// @notice Mint multiple tokens on the `tokenContract` to the caller, using passes
    /// @param passIds The pass token IDs: caller must be owner or operator and passes must have mints remaining
    function mintMultipleFromPasses(
        uint256 quantity,
        uint256[] calldata passIds
    ) external payable started whenNotPaused {
        // CHECKS state and inputs
        uint256 remaining = remainingValueCount;
        if (remaining == 0) revert SoldOut();
        require(quantity > 0, "Must mint at least one token");
        require(quantity <= mintLimit, "Quantity exceeds auction size");

        uint256 price = msg.value / quantity;
        uint256 slotPrice = currentPrice();
        require(price >= slotPrice, "Insufficient payment");

        uint256 passCount = passIds.length;
        require(passCount > 0, "Must include at least one pass");

        // EFFECTS
        if (quantity > remaining) {
            quantity = remaining;
        }

        // CHECKS: check passes and log their usages
        uint256 passUses = 0;
        for (uint256 i = 0; i < passCount; i++) {
            uint256 passId = passIds[i];

            // CHECKS
            uint256 allowance = passAllowance(passId);

            // INTERACTIONS
            for (uint256 j = 0; j < allowance && passUses < quantity; j++) {
                passes.logPassUse(passId, passProjectId);
                passUses++;
            }

            // Don't check more passes than needed
            if (passUses == quantity) break;
        }

        require(passUses > 0, "No mints remaining for provided passes");
        quantity = passUses;

        // EFFECTS
        unchecked {
            // Unchecked arithmetic: mintCount cannot exceed passLimit * number of existing passes
            mintCount[msg.sender] += quantity;
            // Unchecked arithmetic: can't exceed total existing wei; not expected to exceed mintLimit * startPrice
            mintPayment[msg.sender] += msg.value;
        }

        if (slotPrice < lowestPrice) {
            lowestPrice = slotPrice;
        }

        // INTERACTIONS: call mint on known contract (tokenContract.mint contains no external interactions)
        unchecked {
            uint256 startMintId = mintLimit - remainingValueCount;
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = drawNext();
                emit Purchase(msg.sender, startMintId + i, tokenId, price, true);
                try INFT(tokenContract).ownerOf(tokenId) returns (address _owner) {
                    if (_owner == address(0)){
                        INFT(tokenContract).mint(msg.sender, tokenId);
                    } else {
                        INFT(tokenContract).transferFrom(_owner, msg.sender, tokenId);
                    }
                }
                catch {
                    INFT(tokenContract).mint(msg.sender, tokenId);
                }
            }
        }
    }

    // OWNER FUNCTIONS

    /// @notice Mint reserve tokens to the designated `recipient`
    /// @dev Can only be called by the contract `owner`. Reverts if the auction has already started.
    function reserveShuffle(address recipient, uint256 quantity) external unstarted onlyOwner {
        // CHECKS contract state
        uint256 remaining = remainingValueCount;
        if (remaining == 0) revert SoldOut();

        // EFFECTS
        if (quantity > remaining) {
            quantity = remaining;
        }

        unchecked {
            // Unchecked arithmetic: neither value can exceed mintLimit
            reserveCount += quantity;
        }

        emit Reservation(recipient, quantity, reserveCount);

        // INTERACTIONS
        unchecked {
            uint256 tokenId;
            for (uint256 i = 0; i < quantity; i++) {
                tokenId = drawNext();
                try INFT(tokenContract).ownerOf(tokenId) returns (address _owner) {
                    INFT(tokenContract).transferFrom(_owner, msg.sender, tokenId);
                }
                catch {
                    INFT(tokenContract).mint(msg.sender, tokenId);
                }
            }
        }
    }

    event TokenIdsDrawn(uint256[] tokenIds);

    function reserveShuffleVirtual(uint256 quantity) external unstarted onlyOwner {
        // CHECKS contract state
        uint256 remaining = remainingValueCount;
        if (remaining == 0) revert SoldOut();

        // EFFECTS
        if (quantity > remaining) {
            quantity = remaining;
        }

        unchecked {
            // Unchecked arithmetic: neither value can exceed mintLimit
            reserveCount += quantity;
        }

        // INTERACTIONS
        uint256[] memory drawnTokenIds = new uint256[](quantity);
        unchecked {
            for (uint256 i = 0; i < quantity; i++) {
                drawnTokenIds[i] = drawNext();
            }
        }

        // Emit the event with the drawn token IDs
        emit TokenIdsDrawn(drawnTokenIds);
    }


    function reserve(address recipient, uint256[] calldata tokenIds) external unstarted onlyOwner {
        // CHECKS contract state
        uint256 remaining = remainingValueCount;
        uint256 quantity = tokenIds.length;

        if (remaining == 0) revert SoldOut();

        // EFFECTS
        if (quantity > remaining) {
            quantity = remaining;
        }

        unchecked {
            // Unchecked arithmetic: neither value can exceed mintLimit
            reserveCount += quantity;
        }

        emit Reservation(recipient, quantity, reserveCount);

        unchecked {
            for (uint256 i; i < quantity; i++) {
                bool isDrawn = drawSpecific(tokenIds[i]);
                if (!isDrawn) {
                    revert("TokenId already drawn");
                }

                try INFT(tokenContract).ownerOf(tokenIds[i]) returns (address _owner) {
                    INFT(tokenContract).transferFrom(_owner, recipient, tokenIds[i]);
                }
                catch {
                    INFT(tokenContract).mint(recipient, tokenIds[i]);
                }
            }
        }
    }

    function reserveVirtual(address recipient, uint256[] calldata tokenIds) external unstarted onlyOwner {
        // CHECKS contract state
        uint256 remaining = remainingValueCount;
        uint256 quantity = tokenIds.length;

        if (remaining == 0) revert SoldOut();

        // EFFECTS
        if (quantity > remaining) {
            quantity = remaining;
        }

        unchecked {
            // Unchecked arithmetic: neither value can exceed mintLimit
            reserveCount += quantity;
        }

        emit Reservation(recipient, quantity, reserveCount);

        unchecked {
            for (uint256 i; i < quantity; i++) {
                bool isDrawn = drawSpecific(tokenIds[i]);
                if (!isDrawn) {
                    revert("TokenId already drawn");
                }
            }
        }
    }


    /// @notice withdraw auction proceeds
    /// @dev Can only be called by the contract `owner`. Reverts if the final price is unknown, if proceeds have already
    ///  been withdrawn, or if the fund transfer fails.
    function withdraw(address recipient) external onlyOwner {
        // CHECKS contract state
        uint256 remaining = remainingValueCount;
        bool soldOut = remaining == 0;
        uint256 finalPrice = lowestPrice;
        if (!soldOut) {
            finalPrice = auctionStages[auctionStages.length - 1].endPrice;

            // Only allow a withdraw before the auction is sold out if the price has finished falling
            require(currentPrice() == finalPrice, "Price is still falling");
        }

        uint256 totalPayment = (mintLimit - remaining - reserveCount) * finalPrice;
        require(totalPayment > previousPayment, "All funds have been withdrawn");

        // EFFECTS
        uint256 outstandingPayment = totalPayment - previousPayment;
        uint256 balance = address(this).balance;
        if (outstandingPayment > balance) {
            // Escape hatch to prevent stuck funds, but this shouldn't happen
            require(balance > 0, "All funds have been withdrawn");
            outstandingPayment = balance;
        }

        previousPayment += outstandingPayment;
        (bool success, bytes memory data) = recipient.call{value: outstandingPayment}("");
        if (!success) revert FailedWithdraw(outstandingPayment, data);
    }

    /// @notice Update the tokenContract contract address
    /// @dev Can only be called by the contract `owner`. Reverts if the auction has already started.
    function setMintable(address tokenContract_) external unstarted onlyOwner {
        // CHECKS inputs
        require(address(tokenContract_) != address(0), "Token contract must not be the zero address");
        // EFFECTS
        tokenContract = tokenContract_;
    }

    /// @notice Update the auction price ranges and rates of decrease
    /// @dev Since the values are validated against each other, they are all set together. Can only be called by the
    ///  contract `owner`. Reverts if the auction has already started.
    function setPricing(
        uint256 startPrice_,
        AuctionStageConfiguration[] calldata stages_
    ) external unstarted onlyOwner {
        // CHECKS inputs
        uint256 stageCount = stages_.length;
        require(stageCount > 0, "Must specify at least one auction stage");

        // EFFECTS + additional CHECKS
        uint256 previousPrice = startPrice = startPrice_;
        delete auctionStages;

        for (uint256 i; i < stageCount; i++) {
            AuctionStageConfiguration calldata config = stages_[i];
            require(config.endPrice < previousPrice, "Each stage price must be lower than the previous price");
            require(config.endPrice > 1e15, "Stage price too low: check that prices are in wei");

            uint256 priceDifference = previousPrice - config.endPrice;
            require(config.priceDropPerSlot * 25 <= priceDifference, "Each stage must last at least 5 minutes");
            require(
                priceDifference % config.priceDropPerSlot == 0,
                "Stage end price must be reachable by slot price drop"
            );
            require(
                config.priceDropPerSlot * (5 * 60 * 12) >= priceDifference,
                "Stage must not last longer than 12 hours"
            );

            AuctionStage storage newStage = auctionStages.push();
            newStage.duration = (12 * priceDifference) / config.priceDropPerSlot;
            newStage.priceDropPerSlot = config.priceDropPerSlot;
            newStage.endPrice = previousPrice = config.endPrice;
        }
    }

    /// @notice Update the number of total mints
    function setMintLimit(uint256 mintLimit_) external unstarted onlyOwner {
        // CHECKS inputs
        require(reserveCount == 0, 'Cannot change the mint limit once tokens have been reserved');
        require(mintLimit_ >= 10, "Mint limit too low");
        require(passLimit < mintLimit_, "Mint limit must be higher than pass limit");
        require(publicLimit < mintLimit_, "Mint limit must be higher than public limit");

        // EFFECTS
        mintLimit = remainingValueCount = mintLimit_;
    }

    /// @notice Update the per-pass mint limit
    function setPassLimit(uint256 passLimit_) external onlyOwner {
        // CHECKS inputs
        require(passLimit_ != 0, "Pass limit must not be zero");
        require(passLimit_ < mintLimit, "Pass limit must be lower than mint limit");

        // EFFECTS
        passLimit = passLimit_;
    }

    /// @notice Update the public per-wallet mint limit
    function setPublicLimit(uint256 publicLimit_) external onlyOwner {
        // CHECKS inputs
        require(publicLimit_ != 0, "Public limit must not be zero");
        require(publicLimit_ < mintLimit, "Public limit must be lower than mint limit");

        // EFFECTS
        publicLimit = publicLimit_;
        publicLimitRevertMessage = publicLimit_ == 1
            ? "Limited to one purchase without a pass"
            : string.concat("Limited to ", Strings.toString(publicLimit_), " purchases without a pass");
    }

    // VIEW FUNCTIONS

    /// @notice Query the current price
    function currentPrice() public view returns (uint256 price) {
        uint256 time = timeElapsed();

        price = startPrice;
        uint256 stageCount = auctionStages.length;
        uint256 stageDuration;
        AuctionStage storage stage;
        for (uint256 i = 0; i < stageCount; i++) {
            stage = auctionStages[i];
            stageDuration = stage.duration;
            if (time < stageDuration) {
                unchecked {
                    uint256 drop = stage.priceDropPerSlot * (time / 12);
                    return price - drop;
                }
            }

            // Proceed to the next stage
            unchecked {
                time -= stageDuration;
            }
            price = auctionStages[i].endPrice;
        }

        // Auction has reached resting price
        return price;
    }

    /// @notice Query the refund available for the specified `minter`
    function refundAvailable(address minter) public view returns (uint256) {
        uint256 minted = mintCount[minter];
        if (minted == 0) return 0;

        uint256 refundPrice = remainingValueCount == 0 ? lowestPrice : currentPrice();

        uint256 payment = mintPayment[minter];
        uint256 newPayment;
        uint256 refundAmount;
        unchecked {
            // Unchecked arithmetic: newPayment cannot exceed mintLimit * startPrice
            newPayment = minted * refundPrice;
            // Unchecked arithmetic: value only used if newPayment < payment
            refundAmount = payment - newPayment;
        }

        return (newPayment < payment) ? refundAmount : 0;
    }

    // INTERNAL FUNCTIONS

    function _mint(bool passMint) internal whenNotPaused {
        // CHECKS state and inputs
        uint256 remaining = remainingValueCount;
        if (remaining == 0) revert SoldOut();
        uint256 slotPrice = currentPrice();
        require(msg.value >= slotPrice, "Insufficient payment");

        // EFFECTS
        unchecked {
            // Unchecked arithmetic: mintCount cannot exceed mintLimit
            mintCount[msg.sender]++;
            // Unchecked arithmetic: can't exceed this.balance; not expected to exceed mintLimit * startPrice
            mintPayment[msg.sender] += msg.value;
        }

        if (slotPrice < lowestPrice) {
            lowestPrice = slotPrice;
        }

        uint256 mintId = mintLimit - remainingValueCount;
        uint256 tokenId = drawNext();
        emit Purchase(msg.sender, mintId, tokenId, msg.value, passMint);

        // INTERACTIONS: call mint on known contract (tokenContract.mint contains no external interactions)
        try INFT(tokenContract).ownerOf(tokenId) returns (address _owner) {
            if (_owner == address(0)){
                INFT(tokenContract).mint(msg.sender, tokenId);
            } else {
                INFT(tokenContract).transferFrom(_owner, msg.sender, tokenId);
            }
        }
        catch {
            INFT(tokenContract).mint(msg.sender, tokenId);
        }
    }

    // INTERNAL VIEW FUNCTIONS

    function passAllowance(uint256 passId) internal view returns (uint256) {
        // Uses view functions of the passes contract
        require(Delegation.check(msg.sender, passes, passId), "Caller is not pass owner or approved");

        uint256 uses = passes.passUses(passId, passProjectId);
        unchecked {
            return uses >= passLimit ? 0 : passLimit - uses;
        }
    }
}

interface INFT {
  function mint(address to, uint256 tokenId) external;
  function ownerOf(uint256 tokenId) external view returns (address);
  function transferFrom(address from, address to, uint256 tokenId) external;
}