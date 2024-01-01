// SPDX-License-Identifier: NO LICENSE

// Copying, reproduction of this contract code or any part of this contract code and most specifically,

// the part relating to Royalty Enforcement, and / or the part relating to the distribution of Token Rewards,

// without prior written permission from the developer / deployer of this contract is strictly prohibited 

// and whoever copies or reproduces this contract code or any part of this contract code and / or whoever uses 

// such contract containing such copied code without the written prior permission from the developer / deployer 

// of this contract will be liable for legal action 

// and also will be legally liable for monetary damages and / or penalties.




// SEAGOLD - The Next Generation Meta. A Treasure from The Deep Sea

// Digital Marketplace For Crypto Collectibles And Non Fungible Tokens

// Create, Collect, Trade, Lend, Borrow, Stake, Watch, Listen, Earn, Play

// Identity

// Metaverses

// SocialFi

// Games



// Instant Trading Rewards For All Traders ( For both Buyers and Sellers )



// We Respect Creator Economy And Hence We Honor 100% Creator Royalties

// Royalties Are Enforced Directly at the contract level.



// Website: https://seagold.io




pragma solidity ^0.8.0;

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function withdraw(uint256 wad) external payable;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:ERC1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:ERC1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

interface ITest {
    function isERC1155(address nftAddress) external returns (bool);
    function isERC721(address nftAddress) external returns (bool);
}

interface MarketPlace {
    function owner() external view returns (address owner);
}

contract SEAGOLD_NFT_MARKETPLACE is ITest, IERC165, Ownable {
    using SafeMath for uint256;
    using ERC165Checker for address;
    bytes4 public constant IID_ITEST = type(ITest).interfaceId;
    bytes4 public constant IID_IERC165 = type(IERC165).interfaceId;
    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

    struct royaltyInfo {
        bool status;
        bool isMutable;
        address royaltyAddress;
        uint256 royaltyPercentage;
    }

    mapping(address => royaltyInfo) public RoyaltyInfo;

    error TradeErro(bytes23 msgVal);
    error BalErro(bytes23 msgVal);
    error OwnErro(bytes23 msgVal);
    error QtyErro(bytes23 msgVal);
    error AmtErro(bytes23 msgVal);
    error SignErro(bytes23 msgVal);

    IUniswapV2Router02 public immutable uniswapV2Router;

    address public uniswapV2Pair;

    bool public standardRewards;

    bool public buyBackEnabled;

    bool public tradingOpen;

    address public wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    address public tokenAddress;

    address public teamAddress;

    uint256 public buyBackPercent = 100;

    uint256 public feePercent = 0;

    uint256 private rewardK;

    uint256 private buyerShare;

    uint256 private sellerShare;

    constructor(
    ) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        teamAddress = msg.sender;
    }

    receive () external payable {}

    function isERC1155(address nftAddress) external view override returns (bool) {
        return nftAddress.supportsInterface(IID_IERC1155);
    }    
    
    function isERC721(address nftAddress) external view override returns (bool) {
        return nftAddress.supportsInterface(IID_IERC721);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == IID_ITEST || interfaceId == IID_IERC165;
    }

    function setRoyalty(
        address _contractAddress,
        address _royaltyAddress,
        uint256 _royaltyPercentage,
        bool _isMutable  // True means Royalty Settings can be changed. False means Royalty Settings cannot be changed.
    ) public {
        require(
            _contractAddress.supportsInterface(IID_IERC721) || _contractAddress.supportsInterface(IID_IERC1155),
            "Not a NFT Contract"
        );
        require(
                msg.sender == MarketPlace(_contractAddress).owner(),
                "Not the Owner"
        );
        royaltyInfo storage royalty = RoyaltyInfo[_contractAddress];
        require(!royalty.status, "Royalty Already Set");
        require(_royaltyAddress!= address(0) && _royaltyPercentage >= 1 && _royaltyPercentage <= 10, "Not valid data");
        royalty.status = true;
        royalty.isMutable = _isMutable;
        royalty.royaltyAddress = _royaltyAddress;
        royalty.royaltyPercentage = _royaltyPercentage * 1e18;
    }

    function updateRoyalty(
        address _contractAddress,
        address _royaltyAddress,
        uint256 _royaltyPercentage,
        bool _isMutable  // True means Royalty Settings can be changed. False means Royalty Settings cannot be changed.
    ) public {
        require(
             _contractAddress.supportsInterface(IID_IERC721) || _contractAddress.supportsInterface(IID_IERC1155),
            "Not a NFT Contract"
        );
        require(
                msg.sender == MarketPlace(_contractAddress).owner(),
                "Not the Owner"
        );
        royaltyInfo storage royalty = RoyaltyInfo[_contractAddress];
        require(royalty.status, "Set the royalty");
        require(royalty.isMutable, "Not mutable");
        require(_royaltyAddress!= address(0) && _royaltyPercentage >= 1 && _royaltyPercentage <= 10, "Not valid data");
        royalty.isMutable = _isMutable;
        royalty.royaltyAddress = _royaltyAddress;
        royalty.royaltyPercentage = _royaltyPercentage * 1e18;
    }

    function updateMutability(address _contractAddress)
        public
    {
        require(
             _contractAddress.supportsInterface(IID_IERC721) || _contractAddress.supportsInterface(IID_IERC1155),
            "Not a NFT Contract"
        );
        require(
                msg.sender == MarketPlace(_contractAddress).owner(),
                "Not the Owner"
        );
        royaltyInfo storage royalty = RoyaltyInfo[_contractAddress];
        require(royalty.status, "Set the royalty");
        require(royalty.isMutable, "Not mutable");
        royalty.isMutable = false;
    }

    function getRoyaltyInfo(address _contractAddress)
        public
        view
        returns (bool,bool,address,uint256)
    {
        royaltyInfo storage royalty = RoyaltyInfo[_contractAddress];
        return (royalty.status,royalty.isMutable,royalty.royaltyAddress,royalty.royaltyPercentage);
    }

    function checkRoyalty(address _contractAddress) public view returns(bool){
        royaltyInfo storage royalty = RoyaltyInfo[_contractAddress];
        return royalty.status;
    }

    function distributeFee() private {
            uint256 wWethBalance = IERC20(wETH).balanceOf(address(this));
            if (wWethBalance > 1 ether){
                IERC20(wETH).withdraw(wWethBalance);
            }
            if (!buyBackEnabled) {
                payable(address(teamAddress)).transfer(address(this).balance);
            } else {
                uint256 _balance = (address(this).balance);
                uint256 forBuyBack = (_balance * buyBackPercent) / 100;
                uint256 forTeam = _balance - forBuyBack;
                if (forTeam > 0){
                    payable(address(teamAddress)).transfer(forTeam);
                }
                if (forBuyBack > 0){
                    buyBack(forBuyBack);
                }
            }
    }

    function buyBack(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = wETH;
        path[1] = tokenAddress;

      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            address(this),
            block.timestamp.add(300)
        );
    }

    struct saleStruct {
        address adress;
        address conAddr;
        uint64 nftType;
        uint64 tokenId;
        uint64 nooftoken;
        uint256 amount;
    }

    function enableTrading(bool value) public onlyOwner {
        tradingOpen = value;
    }

    function updateRewards(bool value) public onlyOwner {
        standardRewards = value;
    }

    function updateBuyBackEnabled(bool value) public onlyOwner {
        buyBackEnabled = value;
    }

    function updateBuyBackPercent(uint256 _buyBackPercent) public onlyOwner {
        require(_buyBackPercent < 101, "Max BuyBack 100%");
        buyBackPercent = _buyBackPercent;
    }

    function updatefeePercent(uint256 _feePercent) public onlyOwner {
        require(_feePercent < 201, "Max Fee 2%");
        feePercent = _feePercent;
    }

    function setBuyerShare(uint256 _buyerShare) public onlyOwner {
        require(_buyerShare < 6, "Value to be less than 6");
        buyerShare = _buyerShare * 1e30;
    }

    function setSellerShare(uint256 _sellerShare) public onlyOwner {
        require(_sellerShare < 6, "Value to be less than 6");
        sellerShare = _sellerShare;
    }

    function setRewardK(uint256 _rewardK) public onlyOwner {
        rewardK = _rewardK * 1e30;
    }

    function updateTokenAddress(address newTokenAddress) public onlyOwner {
        tokenAddress = newTokenAddress;
    }

    function updateUniswapV2Pair(address newUniswapV2Pair) public onlyOwner {
        uniswapV2Pair = newUniswapV2Pair;
    }

    function updateTeamAddress(address newTeamAddress) public onlyOwner {
        teamAddress = newTeamAddress;
    }

    function acceptBId(
        address[] memory bidaddr,
        address[] memory conAddr,
        uint64[] memory nftType,
        uint64[] memory tokenId,
        uint64[] memory nooftoken,
        uint256[] memory amount
    ) public {

        if(!tradingOpen){
            revert TradeErro("Trading Not Open Yet");
        }

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 2 ether) {
            distributeFee();
        }

        uint256 totalSellerRewards;

        uint256 rewardC;

        if (standardRewards){
            rewardC = rewardK;
        } else{
            uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(uniswapV2Pair));
            uint256 wethBalance = IERC20(wETH).balanceOf(address(uniswapV2Pair));
            uint256 rewardKs = (tokenBalance * 1e28) / wethBalance;
            if (rewardKs > rewardK) {
                rewardC = rewardK;
            } else {
                rewardC = rewardKs;
            }
        }

        for (uint256 i; i < bidaddr.length;) {
            saleStruct memory salestruct;
            salestruct.adress = bidaddr[i];
            salestruct.conAddr = conAddr[i];
            salestruct.nftType = nftType[i];
            salestruct.tokenId = tokenId[i];
            salestruct.nooftoken = nooftoken[i];
            salestruct.amount = amount[i];

        if(IERC20(wETH).allowance(salestruct.adress, address(this)) < salestruct.amount || IERC20(wETH).balanceOf(salestruct.adress) < salestruct.amount){
            revert BalErro("balError");
        }

        if (salestruct.nftType == 721) {
            if(IERC721(salestruct.conAddr).ownerOf(salestruct.tokenId) != msg.sender){
                revert OwnErro("OwnErr");
            }
            IERC721(salestruct.conAddr).safeTransferFrom(msg.sender, salestruct.adress, salestruct.tokenId);
        } else {
            if(IERC1155(salestruct.conAddr).balanceOf(msg.sender,salestruct.tokenId) < salestruct.nooftoken){
               revert  QtyErro("InsuffQty");
            }
            IERC1155(salestruct.conAddr).safeTransferFrom(msg.sender,salestruct.adress,salestruct.tokenId,salestruct.nooftoken,"");
        }

        (,,address royAddress, uint256 royPercentage) = getRoyaltyInfo(salestruct.conAddr);

        uint256 fee = ( salestruct.amount * feePercent ) / 10000;
        uint256 royalty = ( salestruct.amount * royPercentage ) / 1e20;
        uint256 netAmount = salestruct.amount - (fee + royalty);
        
        if (fee > 0){
            IERC20(wETH).transferFrom(salestruct.adress, address(this), fee);
        }
        IERC20(wETH).transferFrom(salestruct.adress, msg.sender, netAmount);
        if (royalty > 0) {
            IERC20(wETH).transferFrom(salestruct.adress, royAddress, royalty);
        }
        
        uint256 buyerRewards = (salestruct.amount * rewardC) / buyerShare;
        uint256 sellerRewards = buyerRewards * sellerShare;

        if (IERC20(tokenAddress).balanceOf(address(this)) > (sellerRewards + buyerRewards)) {
            IERC20(tokenAddress).transfer(salestruct.adress, buyerRewards);
            totalSellerRewards = totalSellerRewards + sellerRewards;
            }

            unchecked {
                i++;
            }
        }
        IERC20(tokenAddress).transfer(msg.sender, totalSellerRewards);
    }

    function buyToken(
        address[] memory seller,
        address[] memory conAddr,
        uint64[] memory nftType,
        uint64[] memory tokenId,
        uint64[] memory nooftoken,
        uint256[] memory amount,
        bytes[] memory signature,
        uint256[] memory nonce,
        uint256 totalamount
    ) public payable {

        if(!tradingOpen){
            revert TradeErro("Trading Not Open Yet");
        }

        if(msg.value < totalamount){
           revert  AmtErro("AmtErr");
        }

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 2 ether) {
            distributeFee();
        }

        uint256 totalBuyerRewards;

        uint256 rewardC;

        if (standardRewards){
            rewardC = rewardK;
        } else{
            uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(uniswapV2Pair));
            uint256 wethBalance = IERC20(wETH).balanceOf(address(uniswapV2Pair));
            uint256 rewardKs = (tokenBalance * 1e28) / wethBalance;
            if (rewardKs > rewardK) {
                rewardC = rewardK;
            } else {
                rewardC = rewardKs;
            }
        }

        for (uint256 i; i < seller.length;) {
            saleStruct memory salestruct;
            salestruct.adress = seller[i];
            salestruct.conAddr = conAddr[i];
            salestruct.nftType = nftType[i];
            salestruct.tokenId = tokenId[i];
            salestruct.nooftoken = nooftoken[i];
            salestruct.amount = amount[i];
            
            bytes32 message = prefixed(keccak256(abi.encodePacked(salestruct.adress, nonce[i])));
             if(recoverSigner(message, signature[i]) != salestruct.adress){
                revert  SignErro("SigWrn");
            }
            
            (,,address royAddress, uint256 royPercentage) = getRoyaltyInfo(salestruct.conAddr);

            uint256 fee = ( salestruct.amount * feePercent ) / 10000;
            uint256 royalty = ( salestruct.amount * royPercentage ) / 1e20;
            uint256 netAmount = salestruct.amount - (fee + royalty);

            if (fee > 0){
            payable(address(this)).transfer(fee);
            }
            payable(salestruct.adress).transfer(netAmount);
            if (royalty > 0) {
                payable(royAddress).transfer(royalty);
            }

            if (salestruct.nftType == 721) {
                if(IERC721(salestruct.conAddr).ownerOf(salestruct.tokenId) != salestruct.adress){
                    revert OwnErro("OwnErr");
                }
                IERC721(salestruct.conAddr).safeTransferFrom(salestruct.adress, msg.sender, salestruct.tokenId);
            } else {
                if(IERC1155(salestruct.conAddr).balanceOf(salestruct.adress,salestruct.tokenId) < salestruct.nooftoken){
                    revert  QtyErro("InsuffQty");
                }
                IERC1155(salestruct.conAddr).safeTransferFrom(salestruct.adress,msg.sender,salestruct.tokenId,salestruct.nooftoken,"");
            }

            uint256 buyerRewards = (salestruct.amount * rewardC) / buyerShare;
            uint256 sellerRewards = buyerRewards * sellerShare;

            if (IERC20(tokenAddress).balanceOf(address(this)) > (sellerRewards + buyerRewards)) {
            IERC20(tokenAddress).transfer(salestruct.adress, sellerRewards);
            totalBuyerRewards = totalBuyerRewards + buyerRewards;
            }

            unchecked {
                i++;
            }
        }
        IERC20(tokenAddress).transfer(msg.sender, totalBuyerRewards);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    function withdrawStuckETH(address payable _address, uint256 _amount)
        public
        onlyOwner
    {
        require(_amount > 0, "Zero Amount");
        require(_amount <= address(this).balance, "Amount exceeds balance");
        _address.transfer(_amount);
    }

    function withdrawStuckERC20(address _token, address _address, uint256 _amount)
        public
        onlyOwner
    {
        require(_amount > 0, "Zero Amount");
        uint256 _amountB = IERC20(_token).balanceOf(address(this));
        require(_amount <= _amountB, "Amount exceeds balance");
        IERC20(_token).transfer(_address, _amount);
    }
}