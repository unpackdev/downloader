/**
 *Submitted for verification at BscScan.com on 2023-04-09
*/

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v4.7.3

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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


// File @openzeppelin/contracts/token/ERC721/IERC721.sol@v4.7.3

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.7.3
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File contracts/dumpex.sol

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;


error NotEnoughEther();
error Payable(uint weiToPay);
error OnlyAdmin();

/// @title Dump Exchange
/// @author Juuso Roinevirta
/// @notice Use this contract to sell NFTs & tokens at a fixed price & to buy them in a Dutch auction
/// @custom:experimental This is an experimental contract.
contract DumpEX {
    mapping(address => uint256) lastSaleNfts;
    mapping(address => uint256) lastSaleTokens;
    address admin;
    address pendingAdmin;

    constructor() {
        admin = msg.sender;
    }

    /// @notice Sell an NFT for 1 wei
    /// @dev There must be an existing approval and some wei in the contract
    /// @param nftAddress the address of the NFT you are selling
    /// @param tokenId the ID of the NFT you are selling
    function sellNFT(address nftAddress, uint256 tokenId) external {
        IERC721 nft = IERC721(nftAddress);

        // requirements
        if (nft.getApproved(tokenId) != address(this)) { revert ("Not approved"); }
        if (address(this).balance == 0) { revert NotEnoughEther(); }

        // transfer the NFT to the pool
        nft.transferFrom(msg.sender, address(this), tokenId);

        // update time of last NFT sale
        lastSaleNfts[nftAddress] = block.timestamp;

        // transfer Ether to the seller
        (bool success, ) = payable(msg.sender).call{value: 1 wei}("");
        require(success, "Transfer failed.");
    }

    /// @notice Buy an NFT at a price determined by a Dutch auction
    /// @param nftAddress the address of the NFT you are buying
    /// @param tokenId the ID of the NFT you are buying
    function buyNFT(address nftAddress, uint256 tokenId) external payable {
        IERC721 nft = IERC721(nftAddress);

        // get current price of the NFT
        uint nftPrice = 100 * 10e18 - (block.timestamp - lastSaleNfts[nftAddress])*10e14;

        // requirements
        if (msg.value < nftPrice) { revert Payable(nftPrice); }

        // transfer NFT to buyer
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /// @notice Sell token(s) for 1 wei
    /// @dev There must be an existing approval and some wei in the contract
    /// @param tokenAddress address of the token you are selling
    /// @param amount number of tokens to sell
    function sellToken(address tokenAddress, uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);

        // requirements
        if (address(this).balance == 0) { revert NotEnoughEther(); }

        // transfer Tokens to the pool
        token.transferFrom(msg.sender, address(this), amount);

        // update time of last Token sale
        lastSaleTokens[tokenAddress] = block.timestamp;

        // transfer Ether to the seller
        payable(msg.sender).transfer(1);
    }

    /// @notice Buy tokens at a price determined by a Dutch auction
    /// @param tokenAddress address of the token you are buying
    /// @param amount number of tokens to buy
    function buyToken(address tokenAddress, uint256 amount) external payable {
        IERC20 token = IERC20(tokenAddress);

        //get current price of Tokens
        uint tokenPrice = (10e18 - (block.timestamp - lastSaleTokens[tokenAddress])*10e14) * amount;

        // requirements
        if (msg.value < tokenPrice) { revert Payable(tokenPrice); }

        // transfer Tokens to the buyer
        token.transfer(msg.sender, amount);
    }

    receive() external payable {}

    /// @notice Only admin: withdraw Ether from the contract
    /// @param amount wei
    function adminWithdrawEther(uint256 amount) external {
        if (msg.sender != admin) { revert OnlyAdmin(); }
        payable(admin).transfer(amount);
    }

    /// @notice Only admin: set a new admin
    /// @param newAdmin address of the new admin
    function setAdmin(address newAdmin) external {
        if (msg.sender != admin) { revert OnlyAdmin(); }
        pendingAdmin = newAdmin;
    }

    /// @notice Pending admin only: accept new admin
    function acceptAdmin() external {
        if (msg.sender != pendingAdmin) { revert ("Not pending admin"); }
        admin = pendingAdmin;
    }
}