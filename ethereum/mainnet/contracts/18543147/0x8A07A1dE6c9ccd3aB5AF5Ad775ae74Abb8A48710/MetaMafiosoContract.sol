pragma solidity ^0.8.0;


// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// 
error TransactionCapExceeded ();

error PublicMintingClosed ();

error ExcessiveOwnedMints ();

error MintZeroQuantity ();

error InvalidPayment ();

error SoftCapExceeded ();

error CapExceeded ();

error IsAlreadyUnveiled ();

error ValueCannotBeZero ();

error CannotBeNullAddress ();

error NoStateChange ();

error PublicMintClosed ();

error AllowlistMintClosed ();

error AddressNotAllowlisted ();

error AllowlistDropTimeHasNotPassed ();

error PublicDropTimeHasNotPassed ();

error DropTimeNotInFuture ();

error ClaimModeDisabled ();

error IneligibleRedemptionContract ();

error TokenAlreadyRedeemed ();

error InvalidOwnerForRedemption ();

error InvalidApprovalForRedemption ();

error ERC721RestrictedApprovalAddressRestricted ();

error NotMaintainer ();

error InvalidTeamAddress ();

error DuplicateTeamAddress ();

error AffiliateNotFound ();

// 
/**
 * Teams is a contract implementation to extend upon Ownable that allows multiple controllers
 * of a single contract to modify specific mint settings but not have overall ownership of the contract.
 * This will easily allow cross-collaboration via Mintplex.xyz.
 **/
abstract contract Teams is Ownable {
  mapping(address => bool) internal team;

  /**
   * @dev Adds an address to the team. Allows them to execute protected functions
   * @param _address the ETH address to add, cannot be 0x and cannot be in team already
   **/
  function addToTeam(address _address) public onlyOwner {
    if (_address == address(0)) revert InvalidTeamAddress();
    if (inTeam(_address)) revert DuplicateTeamAddress();
    team[_address] = true;
  }

  /**
   * @dev Removes an address to the team.
   * @param _address the ETH address to remove, cannot be 0x and must be in team
   **/
  function removeFromTeam(address _address) public onlyOwner {
    if (_address == address(0)) revert InvalidTeamAddress();
    if (!inTeam(_address)) revert InvalidTeamAddress();
    team[_address] = false;
  }

  /**
   * @dev Check if an address is valid and active in the team
   * @param _address ETH address to check for truthiness
   **/
  function inTeam(address _address) public view returns (bool) {
    if (_address == address(0)) revert InvalidTeamAddress();
    return team[_address] == true;
  }

  /**
   * @dev Throws if called by any account other than the owner or team member.
   */
  function _onlyTeamOrOwner() private view {
    bool _isOwner = owner() == _msgSender();
    bool _isTeam = inTeam(_msgSender());
    require(_isOwner || _isTeam, "Team: caller is not the owner or in Team.");
  }

  modifier onlyTeamOrOwner() {
    _onlyTeamOrOwner();
    _;
  }
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)
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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * - The `operator` cannot be the caller.
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

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)
/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)
/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)
/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
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
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
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
            require(denominator > prod1, "Math: mulDiv overflow");

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
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
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
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
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// 
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)
/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
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
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// 
interface IOperatorFilterRegistry {
  function isOperatorAllowed(address registrant, address operator) external view returns (bool);

  function register(address registrant) external;

  function registerAndSubscribe(address registrant, address subscription) external;

  function registerAndCopyEntries(address registrant, address registrantToCopy) external;

  function updateOperator(address registrant, address operator, bool filtered) external;

  function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

  function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

  function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

  function subscribe(address registrant, address registrantToSubscribe) external;

  function unsubscribe(address registrant, bool copyExistingEntries) external;

  function subscriptionOf(address addr) external returns (address registrant);

  function subscribers(address registrant) external returns (address[] memory);

  function subscriberAt(address registrant, uint256 index) external returns (address);

  function copyEntriesOf(address registrant, address registrantToCopy) external;

  function isOperatorFiltered(address registrant, address operator) external returns (bool);

  function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

  function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

  function filteredOperators(address addr) external returns (address[] memory);

  function filteredCodeHashes(address addr) external returns (bytes32[] memory);

  function filteredOperatorAt(address registrant, uint256 index) external returns (address);

  function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

  function isRegistered(address addr) external returns (bool);

  function codeHashOf(address addr) external returns (bytes32);
}

// 
abstract contract OperatorFilterer {
  error OperatorNotAllowed(address operator);
  IOperatorFilterRegistry constant operatorFilterRegistry =
    IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

  constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
    // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
    // will not revert, but the contract will need to be registered with the registry once it is deployed in
    // order for the modifier to filter addresses.
    if (address(operatorFilterRegistry).code.length > 0) {
      if (subscribe) {
        operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
      } else {
        if (subscriptionOrRegistrantToCopy != address(0)) {
          operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
        } else {
          operatorFilterRegistry.register(address(this));
        }
      }
    }
  }

  function _onlyAllowedOperator(address from) private view {
    if (
      !(operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender) &&
        operatorFilterRegistry.isOperatorAllowed(address(this), from))
    ) {
      revert OperatorNotAllowed(msg.sender);
    }
  }

  modifier onlyAllowedOperator(address from) virtual {
    // Check registry code length to facilitate testing in environments without a deployed registry.
    if (address(operatorFilterRegistry).code.length > 0) {
      // Allow spending tokens from addresses with balance
      // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
      // from an EOA.
      if (from == msg.sender) {
        _;
        return;
      }
      _onlyAllowedOperator(from);
    }
    _;
  }
  modifier onlyAllowedOperatorApproval(address operator) virtual {
    _checkFilterOperator(operator);
    _;
  }

  function _checkFilterOperator(address operator) internal view virtual {
    // Check registry code length to facilitate testing in environments without a deployed registry.
    if (address(operatorFilterRegistry).code.length > 0) {
      if (!operatorFilterRegistry.isOperatorAllowed(address(this), operator)) {
        revert OperatorNotAllowed(operator);
      }
    }
  }
}

// 
/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
abstract contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable, Teams, OperatorFilterer {
  using Address for address;
  using Strings for uint256;
  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }
  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }
  uint256 private currentIndex;
  uint256 public immutable collectionSize;
  uint256 public maxBatchSize;
  // Token name
  string private _name;
  // Token symbol
  string private _symbol;
  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;
  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;
  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;
  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;
  /* @dev Mapping of restricted operator approvals set by contract Owner
   * This serves as an optional addition to ERC-721 so
   * that the contract owner can elect to prevent specific addresses/contracts
   * from being marked as the approver for a token. The reason for this
   * is that some projects may want to retain control of where their tokens can/can not be listed
   * either due to ethics, loyalty, or wanting trades to only occur on their personal marketplace.
   * By default, there are no restrictions. The contract owner must deliberatly block an address
   */
  mapping(address => bool) public restrictedApprovalAddresses;

  /**
   * @dev
   * maxBatchSize refers to how much a minter can mint at a time.
   * collectionSize_ refers to how many tokens are in the collection.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) OperatorFilterer(address(0), false) {
    require(collectionSize_ > 0, "ERC721A: collection must have a nonzero supply");
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
    currentIndex = _startTokenId();
  }

  /**
   * To change the starting tokenId, please override this function.
   */
  function _startTokenId() internal view virtual returns (uint256) {
    return 1;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalMinted();
  }

  function currentTokenId() public view returns (uint256) {
    return _totalMinted();
  }

  function getNextTokenId() public view returns (uint256) {
    return _totalMinted() + 1;
  }

  /**
   * Returns the total amount of tokens minted in the contract.
   */
  function _totalMinted() internal view returns (uint256) {
    unchecked {
      return currentIndex - _startTokenId();
    }
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(owner != address(0), "ERC721A: number minted query for the zero address");
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
    uint256 curr = tokenId;
    unchecked {
      if (_startTokenId() <= curr && curr < currentIndex) {
        TokenOwnership memory ownership = _ownerships[curr];
        if (ownership.addr != address(0)) {
          return ownership;
        }
        // Invariant:
        // There will always be an ownership that has an address and is not burned
        // before an ownership that does not have an address and is not burned.
        // Hence, curr will not underflow.
        while (true) {
          curr--;
          ownership = _ownerships[curr];
          if (ownership.addr != address(0)) {
            return ownership;
          }
        }
      }
    }
    revert("ERC721A: unable to determine the owner of token");
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    string memory baseURI = _baseURI();
    string memory extension = _baseURIExtension();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), extension)) : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the baseURI and the tokenId. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev Base URI extension used for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the baseURI, tokenId, and this value. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURIExtension() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev Sets the value for an address to be in the restricted approval address pool.
   * Setting an address to true will disable token owners from being able to mark the address
   * for approval for trading. This would be used in theory to prevent token owners from listing
   * on specific marketplaces or protcols. Only modifible by the contract owner/team.
   * @param _address the marketplace/user to modify restriction status of
   * @param _isRestricted restriction status of the _address to be set. true => Restricted, false => Open
   */
  function setApprovalRestriction(address _address, bool _isRestricted) public onlyTeamOrOwner {
    restrictedApprovalAddresses[_address] = _isRestricted;
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public override onlyAllowedOperatorApproval(to) {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");
    if (restrictedApprovalAddresses[to]) revert ERC721RestrictedApprovalAddressRestricted();
    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );
    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    require(operator != _msgSender(), "ERC721A: approve to caller");
    if (restrictedApprovalAddresses[operator]) revert ERC721RestrictedApprovalAddressRestricted();
    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override onlyAllowedOperator(from) {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721A: transfer to non ERC721Receiver implementer");
  }

  /**
   * @dev Returns whether tokenId exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (_mint),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return _startTokenId() <= tokenId && tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity, bool isAdminMint) internal {
    _safeMint(to, quantity, isAdminMint, "");
  }

  /**
   * @dev Mints quantity tokens and transfers them to to.
   *
   * Requirements:
   *
   * - there must be quantity tokens remaining unminted in the total collection.
   * - to cannot be the zero address.
   * - quantity cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 quantity, bool isAdminMint, bytes memory _data) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");
    // For admin mints we do not want to enforce the maxBatchSize limit
    if (isAdminMint == false) {
      require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");
    }
    _beforeTokenTransfers(address(0), to, startTokenId, quantity);
    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + (isAdminMint ? 0 : uint128(quantity))
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));
    uint256 updatedIndex = startTokenId;
    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }
    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers tokenId from from to to.
   *
   * Requirements:
   *
   * - to cannot be the zero address.
   * - tokenId token must be owned by from.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(address from, address to, uint256 tokenId) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);
    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));
    require(isApprovedOrOwner, "ERC721A: transfer caller is not owner nor approved");
    require(prevOwnership.addr == from, "ERC721A: transfer from incorrect owner");
    require(to != address(0), "ERC721A: transfer to the zero address");
    _beforeTokenTransfers(from, to, tokenId, 1);
    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);
    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));
    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(prevOwnership.addr, prevOwnership.startTimestamp);
      }
    }
    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve to to operate on tokenId
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId, address owner) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set owners to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    if (currentIndex == _startTokenId()) revert("No Tokens Minted Yet");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(ownership.addr, ownership.startTimestamp);
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When from and to are both non-zero, from's tokenId will be
   * transferred to to.
   * - When from is zero, tokenId will be minted for to.
   */
  function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when from and to are both non-zero.
   * - from and to are never both zero.
   */
  function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}
}

// 
contract Affiliate is Context, Teams {
    struct AffiliateAccount {
        address addr;
        uint256 rate;
        uint256 balance;
        uint256 lifetimeBalance;
        uint256 mints;
    }

    uint256 internal affiliateBalance = 0;
    mapping(string => AffiliateAccount) private affiliates;
    mapping(string => bool) internal affiliateExists;
    mapping(address => string) private affiliateCodes;

    function affiliateStatus(address _address) external view returns (string memory code, uint256 rate, uint256 mints, uint256 balance, uint256 lifetimeBalance) {
        string memory _code = affiliateCodes[_address];
        require(affiliateExists[_code], "Address is not an affiliate");
        AffiliateAccount memory affiliate = affiliates[_code];
        return (_code, affiliate.rate, affiliate.mints, affiliate.balance, affiliate.lifetimeBalance);
    }
    
    function addAffiliate(string calldata _code, address _address, uint256 _rate) external onlyTeamOrOwner {
        require(bytes(_code).length > 0, "Invalid code");
        require(_address != address(0), "Invalid address");
        require(_rate > 0, "Rate must be greater than zero");
        require(bytes(affiliateCodes[_address]).length == 0, "Affiliate address already exists");
        require(!affiliateExists[_code], "Affiliate code already exists");

        AffiliateAccount memory affiliate = AffiliateAccount(_address, _rate, 0, 0, 0);
        affiliates[_code] = affiliate;
        affiliateExists[_code] = true;
        affiliateCodes[_address] = _code;
    }

    function creditAffiliate(string calldata _code, uint256 _value, uint256 _mints) internal {
        if (affiliateExists[_code]) {
            AffiliateAccount storage affiliate = affiliates[_code];
            
            // Calculate their earnings from the transaction value
            uint256 earnings = (_value * affiliate.rate) / 100;

            // Update the balance of this affiliate
            affiliate.mints += _mints;
            affiliate.balance += earnings;
            affiliate.lifetimeBalance += earnings;

            // Save the total balance of all affiliates
            affiliateBalance += earnings;
        }
    }

    function _payAffiliate(string memory _code) private {
        require(affiliateExists[_code], "Affiliate does not exist");
        AffiliateAccount storage affiliate = affiliates[_code];
    
        uint256 _balance = affiliate.balance;
        address _address = affiliate.addr;
        require(_balance > 0, "Affiliate does not have a balance");
        require(_address != address(0), "Invalid address");

        (bool success, ) = _address.call{value: _balance}("");
        require(success, "Withdrawal failed");

        // Reset their balance
        affiliate.balance = 0;
        affiliateBalance -= _balance;
    }

    function affiliateWithdraw() external {
        string memory _code = affiliateCodes[_msgSender()];
        require(affiliateExists[_code], "You are not an affiliate");
        _payAffiliate(_code);
    }
}

// 
abstract contract WithdrawableV2 is Teams, Affiliate {
  address[] public payableAddresses = [
    0x8e8772E32F700C623FED03Ce29e2dE47073dB972,
    0x5b409126085223d28f3e2257bcf9eF6fB1c9D735
  ];
  uint256[] public payableFees = [2, 98];
  uint256 public payableAddressCount = 2;

  function withdrawAll() public onlyTeamOrOwner {
    uint256 _balance = address(this).balance;
    uint256 _availableBalance = _balance - affiliateBalance;

    if (_availableBalance <= 0) revert ValueCannotBeZero();
    _withdrawAll(_availableBalance);
  }

  function _withdrawAll(uint256 balance) private {
    for (uint i = 0; i < payableAddressCount; i++) {
      _widthdraw(payableAddresses[i], (balance * payableFees[i]) / 100);
    }
  }

  function _widthdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }
}

// 
abstract contract Feeable is Teams {
  uint256 public PRICE_BASE = 1 ether;
  uint256 public INCREMENT_PERCENT = 6;
  uint256 public INCREMENT_BATCH = 100;

  function setPriceBase(uint256 _feeInWei) external onlyTeamOrOwner {
    PRICE_BASE = _feeInWei;
  }

  function setPriceIncrementPercent(uint256 _incrementPercent) external onlyTeamOrOwner {
    INCREMENT_PERCENT = _incrementPercent;
  }

  function setPriceIncrementBatch(uint256 _incrementBatch) external onlyTeamOrOwner {
    INCREMENT_BATCH = _incrementBatch;
  }

  function getPrice(uint256 _count, uint256 _supply) internal view returns (uint256) {
    uint256 batch = _supply / INCREMENT_BATCH;
    uint256 price = PRICE_BASE;

    for (uint i = 0; i < batch; i++) {
      price += price * INCREMENT_PERCENT / 100;
    }

    return price * _count;
  }
}

// 
abstract contract Allowlist is Teams {
  bytes32 public merkleRoot;
  bool public onlyAllowlistMode = false;

  /**
   * @dev Update merkle root to reflect changes in Allowlist
   * @param _newMerkleRoot new merkle root to reflect most recent Allowlist
   */
  function updateMerkleRoot(bytes32 _newMerkleRoot) public onlyTeamOrOwner {
    if (_newMerkleRoot == merkleRoot) revert NoStateChange();
    merkleRoot = _newMerkleRoot;
  }

  /**
   * @dev Check the proof of an address if valid for merkle root
   * @param _to address to check for proof
   * @param _merkleProof Proof of the address to validate against root and leaf
   */
  function isAllowlisted(address _to, bytes32[] calldata _merkleProof) public view returns (bool) {
    if (merkleRoot == 0) revert ValueCannotBeZero();
    bytes32 leaf = keccak256(abi.encodePacked(_to));
    return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
  }

  function enableAllowlistOnlyMode() public onlyTeamOrOwner {
    onlyAllowlistMode = true;
  }

  function disableAllowlistOnlyMode() public onlyTeamOrOwner {
    onlyAllowlistMode = false;
  }
}

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
  /**
   * @dev Returns true if a 'leaf' can be proved to be a part of a Merkle tree
   * defined by 'root'. For this, a 'proof' must be provided, containing
   * sibling hashes on the branch from the leaf to the root of the tree. Each
   * pair of leaves and each pair of pre-images are assumed to be sorted.
   */
  function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
    return processProof(proof, leaf) == root;
  }

  /**
   * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
   * from 'leaf' using 'proof'. A 'proof' is valid if and only if the rebuilt
   * hash matches the root of the tree. When processing the proof, the pairs
   * of leafs & pre-images are assumed to be sorted.
   *
   * _Available since v4.4._
   */
  function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];
      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = _efficientHash(computedHash, proofElement);
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = _efficientHash(proofElement, computedHash);
      }
    }
    return computedHash;
  }

  function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
    assembly {
      mstore(0x00, a)
      mstore(0x20, b)
      value := keccak256(0x00, 0x40)
    }
  }
}

// 
abstract contract ERC721APlus is
  Ownable,
  Teams,
  ERC721A,
  WithdrawableV2,
  ReentrancyGuard,
  Feeable,
  Allowlist
{
  constructor(string memory tokenName, string memory tokenSymbol) ERC721A(tokenName, tokenSymbol, 20, 2000) {}

  uint8 public constant CONTRACT_VERSION = 2;
  uint256 public softCap = 100;
  bool public softCapEnforced = false;
  string public _baseTokenURI = "ipfs://QmPhkMVtcTCs3Y97XygG73aCj3dGhF1xZ4gwXjjWBRxC7i/";
  string public _baseTokenExtension = ".json";
  bool public mintingOpen = false;
  bool public soulbound = false;

  /**
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When from and to are both non-zero, from's tokenId will be
   * transferred to to.
   * - When from is zero, tokenId will be minted for to.
   */
  function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override(ERC721A) {
    if (soulbound) {
      require(from == address(0), "Transfers are not permitted at the moment");
    }
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  /////////////// Admin Mint Functions
  /**
   * @dev Mints a token to an address with a tokenURI.
   * This is owner only and allows a fee-free drop
   * @param _to address of the future owner of the token
   * @param _qty amount of tokens to drop the owner
   */
  function mintToAdminV2(address _to, uint256 _qty) public onlyTeamOrOwner {
    if (_qty == 0) revert MintZeroQuantity();
    if (currentTokenId() + _qty > collectionSize) revert CapExceeded();
    _safeMint(_to, _qty, true);
  }

  /////////////// PUBLIC MINT FUNCTIONS
  /**
   * @dev Mints tokens to an address in batch.
   * fee may or may not be required*
   * @param _to address of the future owner of the token
   * @param _amount number of tokens to mint
   */
  function mintToMultiple(address _to, uint256 _amount) public payable {
    if (_amount == 0) revert MintZeroQuantity();
    if (_amount > maxBatchSize) revert TransactionCapExceeded();
    if (!mintingOpen) revert PublicMintClosed();
    if (mintingOpen && onlyAllowlistMode) revert PublicMintClosed();
    if (currentTokenId() + _amount > softCap && softCapEnforced) revert SoftCapExceeded();
    if (currentTokenId() + _amount > collectionSize) revert CapExceeded();
    if (msg.value != getPrice(_amount)) revert InvalidPayment();
    _safeMint(_to, _amount, false);
  }

  /**
   * @dev Mints tokens to an address in batch and pays to an affiliate.
   * @param _to address of the future owner of the token
   * @param _amount number of tokens to mint
   * @param _code affiliate code
   */
  function mintToMultipleAF(address _to, uint256 _amount, string calldata _code) public payable {
    if (_amount == 0) revert MintZeroQuantity();
    if (_amount > maxBatchSize) revert TransactionCapExceeded();
    if (!mintingOpen) revert PublicMintClosed();
    if (mintingOpen && onlyAllowlistMode) revert PublicMintClosed();
    if (currentTokenId() + _amount > softCap && softCapEnforced) revert SoftCapExceeded();
    if (currentTokenId() + _amount > collectionSize) revert CapExceeded();
    if (msg.value != getPrice(_amount)) revert InvalidPayment();
    if (!affiliateExists[_code]) revert AffiliateNotFound();
    creditAffiliate(_code, msg.value, _amount);
    _safeMint(_to, _amount, false);
  }

  function openMinting() public onlyTeamOrOwner {
    mintingOpen = true;
  }

  function stopMinting() public onlyTeamOrOwner {
    mintingOpen = false;
  }

  ///////////// ALLOWLIST MINTING FUNCTIONS
  /**
   * @dev Mints tokens to an address using an allowlist.
   * fee may or may not be required*
   * @param _to address of the future owner of the token
   * @param _amount number of tokens to mint
   * @param _merkleProof merkle proof array
   */
  function mintToMultipleAL(address _to, uint256 _amount, bytes32[] calldata _merkleProof) public payable {
    if (!onlyAllowlistMode || !mintingOpen) revert AllowlistMintClosed();
    if (!isAllowlisted(_to, _merkleProof)) revert AddressNotAllowlisted();
    if (_amount == 0) revert MintZeroQuantity();
    if (_amount > maxBatchSize) revert TransactionCapExceeded();
    if (currentTokenId() + _amount > softCap && softCapEnforced) revert SoftCapExceeded();
    if (currentTokenId() + _amount > collectionSize) revert CapExceeded();
    if (msg.value != getPrice(_amount)) revert InvalidPayment();
    _safeMint(_to, _amount, false);
  }

  /**
   * @dev Mints tokens to an address using an allowlist.
   * fee may or may not be required*
   * @param _to address of the future owner of the token
   * @param _amount number of tokens to mint
   * @param _merkleProof merkle proof array
   */
  function mintToMultipleALAF(address _to, uint256 _amount, bytes32[] calldata _merkleProof, string calldata _code) public payable {
    if (!onlyAllowlistMode || !mintingOpen) revert AllowlistMintClosed();
    if (!isAllowlisted(_to, _merkleProof)) revert AddressNotAllowlisted();
    if (_amount == 0) revert MintZeroQuantity();
    if (_amount > maxBatchSize) revert TransactionCapExceeded();
    if (currentTokenId() + _amount > softCap && softCapEnforced) revert SoftCapExceeded();
    if (currentTokenId() + _amount > collectionSize) revert CapExceeded();
    if (msg.value != getPrice(_amount)) revert InvalidPayment();
    if (!affiliateExists[_code]) revert AffiliateNotFound();
    creditAffiliate(_code, msg.value, _amount);
    _safeMint(_to, _amount, false);
  }

  /**
   * @dev Enable allowlist minting fully by enabling both flags
   * This is a convenience function for the Rampp user
   */
  function openAllowlistMint() public onlyTeamOrOwner {
    enableAllowlistOnlyMode();
    mintingOpen = true;
  }

  /**
   * @dev Close allowlist minting fully by disabling both flags
   * This is a convenience function for the Rampp user
   */
  function closeAllowlistMint() public onlyTeamOrOwner {
    disableAllowlistOnlyMode();
    mintingOpen = false;
  }

  /**
   * @dev Allows owner to set Max mints per tx
   * @param _newMaxMint maximum amount of tokens allowed to mint per tx. Must be >= 1
   */
  function setMaxMint(uint256 _newMaxMint) public onlyTeamOrOwner {
    if (_newMaxMint == 0) revert ValueCannotBeZero();
    maxBatchSize = _newMaxMint;
  }

  function contractURI() public pure returns (string memory) {
    return "ipfs://QmXHmWuxDQSRK6JYahXzGK7um5tB5cyHahwaChyBj2DQNw";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function _baseURIExtension() internal view virtual override returns (string memory) {
    return _baseTokenExtension;
  }

  function baseTokenURI() public view returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyTeamOrOwner {
    _baseTokenURI = baseURI;
  }

  function setBaseTokenExtension(string calldata baseExtension) external onlyTeamOrOwner {
    _baseTokenExtension = baseExtension;
  }

  function setSoftCap(uint256 _softCap) external onlyTeamOrOwner {
    softCap = _softCap;
  }

  function setSoftCapEnforced(bool _enforced) external onlyTeamOrOwner {
    softCapEnforced = _enforced;
  }

  function getPrice(uint256 _count) public view returns (uint256) {
    return super.getPrice(_count, totalSupply());
  }

  function setSoulbound(bool _sb) external onlyTeamOrOwner {
    soulbound = _sb;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}

// 
interface IMetaSignals {
    function affiliateStatus(address _address) external view returns (string memory, uint256, uint256, uint256, uint256);
    function addAffiliate(string calldata _code, address _address, uint256 _rate) external;
    function affiliateWithdraw() external;
    function setPriceBase(uint256 _feeInWei) external;
    function setPriceIncrementPercent(uint256 _incrementPercent) external;
    function setPriceIncrementBatch(uint256 _incrementBatch) external;
    function setSoulbound(bool _sb) external;
}

// 
contract MetaMafiosoContract is ERC721APlus {
  constructor() ERC721APlus("MetaMafioso", "METSIG") {}

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721APlus) returns (bool) {
    return interfaceId == type(IMetaSignals).interfaceId
        || super.supportsInterface(interfaceId);
  }
}