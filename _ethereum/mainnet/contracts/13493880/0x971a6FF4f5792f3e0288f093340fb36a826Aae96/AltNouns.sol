//SPDX-License-Identifier: GPL-3.0
/// @title The Alt Nouns ERC-721 token


/*********************************
 * █████████████████████████████ *
 * █████████████████████████████ *
 * ██████░░░░░░░░░██░░░░░░░░░███ *
 * ██████░░███░░░░██░░███░░░░███ *
 * ██░░░░░░███░░░░░░░░███░░░░███ *
 * ██░░██░░███░░░░██░░███░░░░███ *
 * ██░░██░░███░░░░██░░███░░░░███ *
 * ██████░░░░░░░░░██░░░░░░░░░███ *
 * █████████████████████████████ *
 * ██ ALT NOUNS ████████████████ *
 * ██ by @onChainCo ████████████ *
 * █████████████████████████████ *
 *********************************/


pragma solidity ^0.8.0;

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}




/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * Length
     * 
     * Returns the length of the specified string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base)
        internal
        pure
        returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     * 
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(string memory _base, int _length, int _offset)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for (uint i = uint(_offset); i < uint(_offset + _length); i++) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int) {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(string memory _base, string memory _value, uint _offset)
        internal
        pure
        returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }
}




/*
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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}





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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}














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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}







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
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}









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


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
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
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}







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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

/// @title Interface for NounsToken

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

interface INounsToken {
    function dataURI(uint256 tokenId) external view returns (string memory);
}



/*

Behold, an infinite (derivative) work of art.

By On Chain Collective

 ______   __       ______     __   __   ______   __  __   __   __   ______             
/\  __ \ /\ \     /\__  _\   /\ "-.\ \ /\  __ \ /\ \/\ \ /\ "-.\ \ /\  ___\            
\ \  __ \\ \ \____\/_/\ \/   \ \ \-.  \\ \ \/\ \\ \ \_\ \\ \ \-.  \\ \___  \           
 \ \_\ \_\\ \_____\  \ \_\    \ \_\\"\_\\ \_____\\ \_____\\ \_\\"\_\\/\_____\          
  \/_/\/_/ \/_____/   \/_/     \/_/ \/_/ \/_____/ \/_____/ \/_/ \/_/ \/_____/          
                                                                                       
                                     ______   __  __       ______   ______   ______    
                                    /\  == \ /\ \_\ \     /\  __ \ /\  ___\ /\  ___\   
                                    \ \  __< \ \____ \    \ \ \/\ \\ \ \____\ \ \____  
                                     \ \_____\\/\_____\    \ \_____\\ \_____\\ \_____\ 
                                      \/_____/ \/_____/     \/_____/ \/_____/ \/_____/ 
                                                                                       
 */

contract AltNouns is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 private price = 0.25 ether;
    uint256 public priceIncrement = 0.75 ether;
    uint256 public numTokensMinted;
    uint256 public maxPerAddress = 2;

    bool public allSalesPaused = true;
    bool public priceChangesLocked = false;
    bool public dynamicPriceEnabled = true;
    bool public reservedMintsLocked = false;

    mapping(address => uint256) private _mintPerAddress;
    mapping(uint256 => uint256) private _altForId;

    address public nounsTokenContract = 0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03;
    uint256 public nounsTokenIndexOffset;

    /*
     ______  ______   ______   __  __   _____    ______       ______   ______   __   __   _____    ______   __    __   __   __   ______   ______   ______    
    /\  == \/\  ___\ /\  ___\ /\ \/\ \ /\  __-. /\  __ \     /\  == \ /\  __ \ /\ "-.\ \ /\  __-. /\  __ \ /\ "-./  \ /\ "-.\ \ /\  ___\ /\  ___\ /\  ___\   
    \ \  _-/\ \___  \\ \  __\ \ \ \_\ \\ \ \/\ \\ \ \/\ \    \ \  __< \ \  __ \\ \ \-.  \\ \ \/\ \\ \ \/\ \\ \ \-./\ \\ \ \-.  \\ \  __\ \ \___  \\ \___  \  
     \ \_\   \/\_____\\ \_____\\ \_____\\ \____- \ \_____\    \ \_\ \_\\ \_\ \_\\ \_\\"\_\\ \____- \ \_____\\ \_\ \ \_\\ \_\\"\_\\ \_____\\/\_____\\/\_____\ 
      \/_/    \/_____/ \/_____/ \/_____/ \/____/  \/_____/     \/_/ /_/ \/_/\/_/ \/_/ \/_/ \/____/  \/_____/ \/_/  \/_/ \/_/ \/_/ \/_____/ \/_____/ \/_____/ 

     */

    // The almighty pseudo random number generator
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    // Uses blockhash, tokenId, etc. as inputs for random(), and returns a random number between minNum & maxNum
    function pluckNum(uint256 tokenId, string memory keyPrefix, uint256 minNum, uint256 maxNum) internal view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(blockhash(block.number - 1), keyPrefix, toString(tokenId), minNum, maxNum,_msgSender())));
        uint256 num = rand % (maxNum - minNum + 1) + minNum;
        return num;
    }

    // Uses blockhash and tokenId as inputs for random() for new Alt Nouns, or returns stored Alt Type for existing Alt Nouns
    function getAltType(uint256 tokenId) private view returns (uint256) {
        if (_altForId[tokenId] == 0) {
            uint256 rand = random(string(abi.encodePacked(blockhash(block.number - 1), toString(tokenId))));
            uint256 altType = rand % 19;

            return altType;
        } else {
            return _altForId[tokenId] - 1;
        }
    }

    /*
     ______   __       ______     ______  ______   ______   __   ______  ______    
    /\  __ \ /\ \     /\__  _\   /\__  _\/\  == \ /\  __ \ /\ \ /\__  _\/\  ___\   
    \ \  __ \\ \ \____\/_/\ \/   \/_/\ \/\ \  __< \ \  __ \\ \ \\/_/\ \/\ \___  \  
     \ \_\ \_\\ \_____\  \ \_\      \ \_\ \ \_\ \_\\ \_\ \_\\ \_\  \ \_\ \/\_____\ 
      \/_/\/_/ \/_____/   \/_/       \/_/  \/_/ /_/ \/_/\/_/ \/_/   \/_/  \/_____/ 

     */

    string[19] altNames = ['Jittery','Wavy','Uhhhhh','Glitching','Static','Immobilized','Snapped','?????','Anti-noun','Wall','Warped','Totem','Outta Focus','Spirit','Collapsing','Exploding','Nether-noun','Distorted','Fractionalize'];

    function getTraits(uint256 tokenId) private view returns (string memory) {

        uint256 altType = getAltType(tokenId);
        string[3] memory parts;

        parts[0] = ', "attributes": [{"trait_type": "Alteration","value": "';
        parts[1] = altNames[altType];
        parts[2] = '"}], ';

        string memory result = string(abi.encodePacked(parts[0], parts[1], parts[2]));

        return result;
    }

    /*
     ______   __   __ ______       __    __   ______   __   __   __   ______  __  __   __       ______   ______  __   ______   __   __    
    /\  ___\ /\ \ / //\  ___\     /\ "-./  \ /\  __ \ /\ "-.\ \ /\ \ /\  == \/\ \/\ \ /\ \     /\  __ \ /\__  _\/\ \ /\  __ \ /\ "-.\ \   
    \ \___  \\ \ \'/ \ \ \__ \    \ \ \-./\ \\ \  __ \\ \ \-.  \\ \ \\ \  _-/\ \ \_\ \\ \ \____\ \  __ \\/_/\ \/\ \ \\ \ \/\ \\ \ \-.  \  
     \/\_____\\ \__|  \ \_____\    \ \_\ \ \_\\ \_\ \_\\ \_\\"\_\\ \_\\ \_\   \ \_____\\ \_____\\ \_\ \_\  \ \_\ \ \_\\ \_____\\ \_\\"\_\ 
      \/_____/ \/_/    \/_____/     \/_/  \/_/ \/_/\/_/ \/_/ \/_/ \/_/ \/_/    \/_____/ \/_____/ \/_/\/_/   \/_/  \/_/ \/_____/ \/_/ \/_/ 

     */

    // Returns alterations
    function getAlteration(uint256 tokenId) private view returns (string memory) {
        string memory feTurbulence;
        string memory feDisplacementMap;
        string memory feTurbulenceAnim;
        string memory feDisplacementMapAnim;

        uint256 altType = getAltType(tokenId);

        if (altType == 0) {
            // Jittery
            feTurbulence = '0.035';
            feDisplacementMap = '9';
            feTurbulenceAnim = '<animate attributeName="baseFrequency" begin="0s" dur="0.15s" values="0.0812;0.0353;0.0041;0.0424;0.0010;0.0934" repeatCount="indefinite"/>';
        } else if (altType == 1) {
            // Wavy
            feTurbulence = string(abi.encodePacked('0.0',toString(pluckNum(tokenId, "Way", 1, 99)),' ','0.0',toString(pluckNum(tokenId, "Vee", 1, 99))));
            feDisplacementMap = '50';
        } else if (altType == 2) {
            // Uhhhhh
            feTurbulence = string(abi.encodePacked('0.0',toString(pluckNum(tokenId, "Uhhhhh", 15, 20))));
            feDisplacementMap = toString(pluckNum(tokenId, "Uhhhhh", 100, 300));
        } else if (altType == 3) {
            // Glitching
            return '<feDisplacementMap in="SourceGraphic" scale="0"><animate attributeName="scale" begin="0s" dur="10s" values="18.51;16.14;-7.81;4.40;-5.97;5.83;-4.63;8.88;-6.38;11.70;9.35;-14.77;-18.40;8.72;-12.61;14.69;6.56;11.47;-5.59;13.16;19.81;3.56;-1.47;3.95;-16.19;-8.11;-3.04;-10.54;-2.04;-14.23;2.00;-12.81;16.28;-0.54;7.18;-1.52;-10.86;-9.92;-7.48;-0.47;-15.37;17.88;19.83;-10.57;5.75;5.67;-1.84;10.87;1.80;8.13;15.44;-11.35;7.77;-15.39;-18.19;14.66;-7.26;-14.34;-14.41;-3.52;-13.27;-7.34;-19.83;17.63;-14.66;-13.68;-18.70;10.14;0.93;-17.23;15.29;2.20;-0.94;-16.04;-0.55;15.80;-7.77;-12.51;-1.13;-11.18;-15.50;5.72;-13.99;-7.17;-2.19;10.36;-11.09;5.68;-15.20;3.09;-6.79;13.58;-12.04;-10.05;17.14;1.32;-15.67;-14.96;-1.01;-3.94;-11.90;-13.77;-2.27;14.63;12.37;-19.31;-3.99;-13.19;14.06;-15.91;-5.03;-6.54;19.74;-5.67;15.57;-6.80;14.24;2.03;-19.11;-14.10;0.35;-19.23;-13.11;12.04;9.69;13.88;5.13;11.94" repeatCount="indefinite"/></feDisplacementMap>';
        } else if (altType == 4) {
            // Static
            return '<feTurbulence numOctaves="3" seed="2" baseFrequency="0.02 0.05" type="fractalNoise"><animate attributeName="baseFrequency" begin="0s" dur="60s" values="0.002 0.06;0.004 0.08;0.002 0.06" repeatCount="indefinite"/></feTurbulence><feDisplacementMap scale="20" in="SourceGraphic"></feDisplacementMap>';
        } else if (altType == 5) {
            // Immobilized
            feTurbulence = '0.5';
            feDisplacementMap = '0';
            feDisplacementMapAnim = '<animate attributeName="scale" begin="0s" dur="0.5s" values="36.72;58.84;36.90;14.99;13.26;47.30;58.24;21.58;46.51;40.17;35.83;36.08;42.74;32.16;46.57;33.67;17.31;52.09;30.80;40.37;43.99;36.21;16.18;20.04;15.72;50.92;41.35;26.12;31.38;30.41;59.51;10.51;45.48;19.59;58.88;33.92;26.88;13.50;31.85;43.88;33.05;22.82;56.26;27.90;51.95;26.47;27.13;32.41;18.12;52.98;50.04;17.62;27.43;52.81;21.61;15.11;25.89;27.39;39.35;51.29" repeatCount="indefinite"/>';
        } else if (altType == 6) {
            // Snapped
            feTurbulence = string(abi.encodePacked('0.',toString(pluckNum(tokenId, "Snapped", 100, 500))));
            feDisplacementMap = toString(pluckNum(tokenId, "Snapped", 100, 500));
        } else if (altType == 7) {
            // ?????
            feTurbulence = string(abi.encodePacked('0.0',toString(pluckNum(tokenId, "?????", 100, 500)),'" numOctaves="10'));
            feDisplacementMap = toString(pluckNum(tokenId, "?????", 200, 300));
        } else if (altType == 8) {
            // Anti-noun
            return '<feColorMatrix in="SourceGraphic" type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0"/>';
        } else if (altType == 9) {
            // Wall
            return '<feTile in="SourceGraphic" x="90" y="100" width="140" height="100" /><feTile/>';
        } else if (altType == 10) {
            // Warped
            return '<feTile in="SourceGraphic" x="0" y="140" width="320" height="20" /><feTile/>';
        } else if (altType == 11) {
            // Totem
            return '<feTile in="SourceGraphic" x="0" y="100" width="320" height="80" /><feTile/>';
        } else if (altType == 12) {
            // Outta Focus
            return '<feGaussianBlur in="SourceGraphic" stdDeviation="3"><animate attributeName="stdDeviation" begin="0s" dur="4s" values="0;4;3;5;3;2;5;7;8;10;15;0;0;0;0;0;0;0;0" repeatCount="indefinite"/></feGaussianBlur>';
        } else if (altType == 13) {
            // Spirit
            return '<feColorMatrix type="matrix" values=".33 .33 .33 0 0 .33 .33 .33 0 0 .33 .33 .33 0 0  0 0 0 0.2 0"></feColorMatrix>';
        } else if (altType == 14) {
            // Collapsing
            return '<feTurbulence baseFrequency="0.05" type="fractalNoise" numOctaves="9"></feTurbulence><feDisplacementMap in="SourceGraphic" scale="200"><animate attributeName="scale" begin="0s" dur="16s" values="40;550;1;40" fill="freeze" repeatCount="indefinite"/></feDisplacementMap><feMorphology operator="erode" radius="25"><animate attributeName="radius" begin="0s" dur="16s" values="1;25;1;1" fill="freeze" repeatCount="indefinite"/></feMorphology>';
        } else if (altType == 15) {
            // Exploding
            return string(abi.encodePacked('<feMorphology operator="dilate" radius="',toString(pluckNum(tokenId, "Explode", 5, 40)),'"></feMorphology>'));
        } else if (altType == 16) {
            // Nether-noun
            return '<feTile in="SourceGraphic" x="90" y="100" width="140" height="100" /><feTile x="0" y="0" width="320" height="320"/><feBlend in2="SourceGraphic" mode="color-burn"/><feTile x="0" y="0" width="320" height="320"/><feBlend in2="SourceGraphic" mode="color-burn"/><feTile x="0" y="0" width="320" height="320"/><feBlend in2="SourceGraphic" mode="color-burn"/>';
        } else if (altType == 17) {
            // Distorted
            return '<feTile id="eye" in="SourceGraphic" x="142.5" y="110" width="45" height="50" /><feTile/><feTile in2="strip" x="0" y="0" width="320" height="320"/><feBlend in2="SourceGraphic" mode="exclusion"/>';
        } else if (altType == 18) {
            // Fractionalize
            return '<feTurbulence baseFrequency="0.01 0.01" type="fractalNoise" numOctaves="5" seed="12453"><animate attributeName="seed" begin="0s" dur="16s" values="1;20;160" repeatCount="indefinite" /></feTurbulence><feDisplacementMap in="SourceGraphic" scale="300"><animate attributeName="scale" begin="0s" dur="16s" values="1;200;1000;1;1" repeatCount="indefinite" /></feDisplacementMap>';
        }

        string memory result = string(abi.encodePacked('<feTurbulence baseFrequency="',feTurbulence,'" type="fractalNoise">',feTurbulenceAnim,'</feTurbulence><feDisplacementMap in="SourceGraphic" scale="',feDisplacementMap,'">',feDisplacementMapAnim,'</feDisplacementMap>'));

        return result;
    }

    function altNoun(string memory noun, uint256 tokenId) private view returns (string memory) {

        // Decoding the noun tokenURI
        string memory decodedNoun = string(Base64.decode(Strings._substring(noun, int256(Strings.length(noun) - 29), 29)));

        // Finds the index of ';' in decoded tokenURI & adds 8 to it (for 'base64,') to set the starting index for the encoded SVG
        uint256 index = uint256(Strings.indexOf(decodedNoun, ';'));
        index = index+8;

        // Substring subtracts 2 from (length - index) to skip the last two characters, i.e. '"}'
        string memory nounSVG = Strings._substring(decodedNoun, int256(Strings.length(decodedNoun) - index - 2), int256(index));

        // Decoding the noun encoded SVG
        bytes memory SVG = Base64.decode(nounSVG);

        // Opening SVG tag
        string memory openingTag = '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">';

        // Grabbing the Noun inside the SVG tag
        string memory innerSVG = getInnerSVG(SVG);

        // Opening <g> tag for filters
        string memory openingGTag = '<g filter="url(#alteration)">';

        // Closing <g> tag and alteration filter
        string memory alterationAndClosingTag = string(abi.encodePacked('</g><defs><filter id="alteration" x="-50%" y="-50%" width="200%" height="200%">',getAlteration(tokenId),'</filter></defs></svg>'));

        // Concatenating everything to get the final Alt Noun SVG
        return string(abi.encodePacked(openingTag,openingGTag,innerSVG,alterationAndClosingTag));
    }

    function getInnerSVG(bytes memory svgBytes) internal pure returns (string memory) {
        bytes memory result = new bytes(svgBytes.length - 122);
        for(uint i = 0; i < result.length; i++) {
            result[i] = svgBytes[i+116];
        }
        return string(result);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory noun = INounsToken(nounsTokenContract).dataURI(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Alt Noun ', toString(tokenId), '", "description": "Hmmm... Something is up with Alt Noun ', toString(tokenId), '"',getTraits(tokenId),'"image": "data:image/svg+xml;base64,', Base64.encode(bytes(altNoun(noun, tokenId))), '"}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }

    /*
     __    __   __   __   __   ______  __   __   __   ______       ______  __  __   __   __   ______   ______  __   ______   __   __   ______    
    /\ "-./  \ /\ \ /\ "-.\ \ /\__  _\/\ \ /\ "-.\ \ /\  ___\     /\  ___\/\ \/\ \ /\ "-.\ \ /\  ___\ /\__  _\/\ \ /\  __ \ /\ "-.\ \ /\  ___\   
    \ \ \-./\ \\ \ \\ \ \-.  \\/_/\ \/\ \ \\ \ \-.  \\ \ \__ \    \ \  __\\ \ \_\ \\ \ \-.  \\ \ \____\/_/\ \/\ \ \\ \ \/\ \\ \ \-.  \\ \___  \  
     \ \_\ \ \_\\ \_\\ \_\\"\_\  \ \_\ \ \_\\ \_\\"\_\\ \_____\    \ \_\   \ \_____\\ \_\\"\_\\ \_____\  \ \_\ \ \_\\ \_____\\ \_\\"\_\\/\_____\ 
      \/_/  \/_/ \/_/ \/_/ \/_/   \/_/  \/_/ \/_/ \/_/ \/_____/     \/_/    \/_____/ \/_/ \/_/ \/_____/   \/_/  \/_/ \/_____/ \/_/ \/_/ \/_____/ 
                                                                                                                                             
    */

    // Checks if a supplied tokenId is a valid noun
    function isNounValid(uint256 tokenId) private view returns (bool) {
        bool isValid = (tokenId + nounsTokenIndexOffset == IERC721Enumerable(nounsTokenContract).tokenByIndex(tokenId));
        return isValid;
    }

    // Updates nounsTokenIndexOffset. Default value is 0 (since indexOf(tokenId) check should match tokenId), but in case a Noun is burned, the offset may require a manual update to allow Alt Nouns to be minted again
    function setNounsTokenIndexOffset(uint256 newOffset) public onlyOwner {
        nounsTokenIndexOffset = newOffset;
    }

    // Mint function that saves the Alt Type (for future tokenURI reads), mints the supplied tokenId and increments counters
    function mint(address destination, uint256 tokenId) private {
        require(isNounValid(tokenId), "This noun does not exist (yet). So its Alt Noun cannot exist either.");
        
        _altForId[tokenId] = getAltType(tokenId) + 1;
        _safeMint(destination, tokenId);
        numTokensMinted += 1;
        _mintPerAddress[msg.sender] += 1;
    }
    
    // Public minting for a supplied tokenId, except for every 10th Alt Noun
    function publicMint(uint256 tokenId) public payable virtual {
        require(!allSalesPaused, "Sales are currently paused");
        require(tokenId%10 != 0, "Every 10th Alt Noun is reserved for Noun holders and Alt Nounders, in perpetuity");
        require(getCurrentPrice() == msg.value, "ETH amount is incorrect");
        require(_mintPerAddress[msg.sender] < maxPerAddress,  "You can't exceed the minting limit for your wallet");
        mint(_msgSender(),tokenId);
    }
    
    // Allows Noun holders to mint any Alt Noun for a supplied tokenId, including every 10th Alt Noun
    function nounHolderMint(uint256 tokenId) public payable virtual {
        require(!allSalesPaused, "Sales are currently paused");
        require(IERC721Enumerable(nounsTokenContract).balanceOf(_msgSender()) > 0, "Every 10th Alt Noun is reserved for Noun holders and Alt Nounders, in perpetuity");
        require(getCurrentPrice() == msg.value, "ETH amount is incorrect");
        require(_mintPerAddress[msg.sender] < maxPerAddress,  "You can't exceed this wallet's minting limit");
        mint(_msgSender(),tokenId);
    }
    
    // Allows owner to mint any available tokenId. To be used with discretion & lockable via lockReservedMints()
    function reservedMint(uint256 tokenId) public payable onlyOwner {
        require(!reservedMintsLocked, "Reserved mints locked. Oops lol");
        mint(_msgSender(),tokenId);
    }

    /*
     ______   ______   __       ______       __  __   ______  __   __       __   ______  __  __       ______  __  __   __   __   ______   ______  __   ______   __   __   ______    
    /\  ___\ /\  __ \ /\ \     /\  ___\     /\ \/\ \ /\__  _\/\ \ /\ \     /\ \ /\__  _\/\ \_\ \     /\  ___\/\ \/\ \ /\ "-.\ \ /\  ___\ /\__  _\/\ \ /\  __ \ /\ "-.\ \ /\  ___\   
    \ \___  \\ \  __ \\ \ \____\ \  __\     \ \ \_\ \\/_/\ \/\ \ \\ \ \____\ \ \\/_/\ \/\ \____ \    \ \  __\\ \ \_\ \\ \ \-.  \\ \ \____\/_/\ \/\ \ \\ \ \/\ \\ \ \-.  \\ \___  \  
     \/\_____\\ \_\ \_\\ \_____\\ \_____\    \ \_____\  \ \_\ \ \_\\ \_____\\ \_\  \ \_\ \/\_____\    \ \_\   \ \_____\\ \_\\"\_\\ \_____\  \ \_\ \ \_\\ \_____\\ \_\\"\_\\/\_____\ 
      \/_____/ \/_/\/_/ \/_____/ \/_____/     \/_____/   \/_/  \/_/ \/_____/ \/_/   \/_/  \/_____/     \/_/    \/_____/ \/_/ \/_/ \/_____/   \/_/  \/_/ \/_____/ \/_/ \/_/ \/_____/ 
                                                                                                                                                                                
     */

    // Returns the current price per mint
    function getCurrentPrice() public view returns (uint256 dynamicPrice) {

        // Since solidity doesn't support floats, supplyDiv will be 0 for <100, 1 for 100 to 200 etc.
        uint256 supplyDiv = totalSupply() / 100;

        // If dynamic pricing disabled or <100 minted, return price
        if (supplyDiv == 0 || !dynamicPriceEnabled) {
            return price;
        }

        // Otherwise, price = priceIncrement added to itself, once for every 100 Alt Noun mints

        dynamicPrice = 0 ether;

        for (uint256 index = 0; index < supplyDiv; index++) {
            dynamicPrice = dynamicPrice + priceIncrement;
        }

        return dynamicPrice;
    }

    // Pauses all sales, except reserved mints
    function toggleAllSalesPaused() public onlyOwner {
        allSalesPaused = !allSalesPaused;
    }
    
    // Locks all pricing states, forever
    function lockPriceChanges() public onlyOwner {
        priceChangesLocked = true;
    }

    // Locks owners ability to use reservedMints()
    function lockReservedMints() public onlyOwner {
        reservedMintsLocked = true;
    }
    
    // Sets mint price
    function setPrice(uint256 newPrice) public onlyOwner {
        require(!priceChangesLocked, "Price changes are now locked");
        price = newPrice;
    }
    
    // Toggles dynamic pricing
    function toggleDynamicPrice() public onlyOwner {
        require(!priceChangesLocked, "Price changes are now locked");
        dynamicPriceEnabled = !dynamicPriceEnabled;
    }
    
    // Sets dynamic pricing increment that gets added to the price after ever 100 mints
    function setPriceIncrement(uint256 newPriceIncrement) public onlyOwner {
        require(!priceChangesLocked, "Price changes are now locked");
        priceIncrement = newPriceIncrement;
    }

    // Withdraws contract balance to contract owners account
    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    constructor() ERC721("AltNouns", "ALTNOUNS") Ownable() {}
}



/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
    
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";
    
    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}