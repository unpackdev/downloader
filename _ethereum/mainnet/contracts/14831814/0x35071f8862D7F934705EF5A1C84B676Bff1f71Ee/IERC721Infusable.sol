// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC721.sol";
import "./IERC20.sol";

/**
 * @title Interface for optional ERC20 Infusion addition for ERC-721 Non-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *
 * Interface Id = 0x7c0a3766
 */
interface IERC721Infusable is IERC721 {
    /**
     * @dev Emitted when _tokenWithdraw() transfers `_msgSender` `_erc20TokenQty`
     * ERC20 tokens from `tokenId`
     */
    event TokenWithdraw(
        address _msgSender,
        uint256 _erc20TokenQty,
        uint256 tokenId
    );

    /**
     * @dev Emitted when _tokenInfuse() infuses `tokenId` with `_erc20TokenQty`
     * ERC20 tokens.
     */
    event TokenInfuse(uint256 tokenId, uint256 _erc20TokenQty);

    /**
     * @dev Emitted when _setWithdrawLock() locks `tokenId` for `lockWeeks` weeks.
     */
    event SetWithdrawLock(uint256 tokenId, uint256 lockWeeks);

    /**
     * @dev Withdraws {ERC20} tokens from `tokenId` to _msgSender().
     *
     * NOTE: The use of block.timestamp is acceptable in this function as the
     * minimum lock duration is 1 week.  This function implements nonReentrant
     * modifier as it may be interacting with a malicious {ERC20} contract.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - `_msgSender()` must be the owner - approved are not allowed to withdraw.
     *   This prevents fringe cases of malicious contracts draining infused
     *   tokens before transferring `tokenId` to its new owner.  Withdraw lock
     *   would prevent this, but it may not be in use.
     * - block.timestamp must be > `_withdrawLockedUntil[tokenId]`
     */
    function tokenWithdraw(uint256 tokenId) external;

    /**
     * @dev Infuses {ERC20} tokens from _msgSender() to `tokenId`.
     *
     * NOTE: This function implements nonReentrant modifier as it may be
     * interacting with a malicious {ERC20} contract.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function tokenInfuse(uint256 tokenId, uint256 _erc20TokenQty) external;

    /**
     * @dev Sets a timed withdraw lock for infused {ERC20} tokens.  Prevents
     * withdraw until block.timestamp exceeds lock duration.  Useful for
     * preventing malicious withdraws, or forced vesting.
     *
     * NOTE: The use of block.timestamp is acceptable in this function as the
     * minimum lock duration is 1 week.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - Must be owner or approved
     * - Qty of {ERC20} to infuse must be > 0
     * - Must not be currently locked
     */
    function setWithdrawLock(uint256 tokenId, uint256 lockWeeks) external;

    /**
     * @dev Returns the qty of {ERC20} tokens infused for a given `tokenId`.
     */
    function totalInfused(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns the epoch timestamp when {ERC20} token withdraw unlocks
     */
    function getWithdrawUnlockTime(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns the address of the {ERC20} token being infused.
     */
    function infusedToken() external view returns (IERC20);

    /**
     * @dev Returns the max number of weeks a token can be locked for
     */
    function maxWithdrawLockWeeks() external view returns (uint256);
}
