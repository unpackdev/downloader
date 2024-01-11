// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./SafeERC20.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Infusable.sol";

/**
 * @title Optional ERC20 Infusion addition for ERC-721 Non-Fungible Token Standard
 * @author Ryan Farley <ryan@artmtoken.com>
 * @dev This implements an optional extension of {ERC721} that provides a simple
 * mechanism for "infusing" and "withdrawing" {ERC20} tokens from a given tokenId.
 *
 * This contract was designed to be inherited by a child contract that can
 * implement access controls & the necessary logic to secure _tokenWithdraw(),
 *  _tokenInfuse(), and _setWithdrawLock().
 *
 * This contract is limited to a single instance of an {ERC20} which must be
 * provided to the constructor.  This contract implements a simple timelocking
 * mechanism to restrict when {ERC20} tokens may be withdrawn from a tokenId.
 *
 * Useful for:
 * - "Asset-backing" a single `tokenId` with a specific qty of {ERC20}
 * - Time-locking {ERC20} tokens for vesting
 * - Time-locking {ERC20} tokens to prevent withdraw during sale or auction
 *
 * NOTE: This contract does not allow approved accounts to call tokenWithdraw()
 * by design.  See {IERC721Infusable-tokenWithdraw} for details.
 */
abstract contract ERC721Infusable is ERC721, IERC721Infusable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // The {ERC20} token this contract uses
    IERC20 private immutable _erc20Token;

    // Max number of weeks infused {ERC20} tokens can be locked
    uint256 private immutable _maxWithdrawLockWeeks;

    // Mapping of `tokenId` to qty of {ERC20} tokens being held
    mapping(uint256 => uint256) private _tokenInfusedQty;

    // Mapping of `tokenId` to epoch timestamp representing unlock time.
    mapping(uint256 => uint256) private _withdrawLockedUntil;

    /**
     * @dev Initializes the contract by specifying a desired {ERC20} contract
     * for infusion, and setting a `maxWithdrawLockWeeks_` value.  This is
     * done to prevent accidental lock times of extreme, undesirable values.
     *
     * Requirements:
     *
     * - `erc20Token_` must not be the zero address.
     * - `maxWithdrawLockWeeks_` must be > 0
     */
    constructor(IERC20 erc20Token_, uint256 maxWithdrawLockWeeks_) {
        require(address(erc20Token_) != address(0), "ERC721Infusable: infused token is the zero address");
        require(maxWithdrawLockWeeks_ > 0, "ERC721Infusable: max withdraw lock weeks must be greater than 0");

        _erc20Token = erc20Token_;
        _maxWithdrawLockWeeks = maxWithdrawLockWeeks_;
    }

    /**
     * @dev See {IERC721Infusable-tokenWithdraw}.
     */
    function tokenWithdraw(uint256 tokenId) external virtual override nonReentrant {
        require(_exists(tokenId), "ERC721Infusable: nonexistent token");
        require(_msgSender() == ownerOf(tokenId), "ERC721Infusable: caller is not owner");

        _beforeTokenWithdraw(tokenId);

        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp > _withdrawLockedUntil[tokenId], "ERC721Infusable: withdraw currently locked");

        _tokenWithdraw(tokenId);
    }

    /**
     * @dev See {IERC721Infusable-tokenInfuse}.
     */
    function tokenInfuse(uint256 tokenId, uint256 _erc20TokenQty) external virtual override nonReentrant {
        require(_exists(tokenId), "ERC721Infusable: nonexistent token");

        _tokenInfuse(tokenId, _erc20TokenQty);
    }

    /**
     * @dev See {IERC721Infusable-setWithdrawLock}.
     */
    function setWithdrawLock(uint256 tokenId, uint256 lockWeeks) external virtual override {
        require(_exists(tokenId), "ERC721Infusable: nonexistent token");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Infusable: caller is not owner nor approved");
        require(_tokenInfusedQty[tokenId] > 0, "ERC721Infusable: must be infused to lock");

        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp > _withdrawLockedUntil[tokenId], "ERC721Infusable: withdraw already locked");

        _setWithdrawLock(tokenId, lockWeeks);
    }

    /**
     * @dev See {IERC721Infusable-totalInfused}.
     */
    function totalInfused(uint256 tokenId) external view override returns (uint256) {
        require(_exists(tokenId), "ERC721Infusable: nonexistent token");
        return _tokenInfusedQty[tokenId];
    }

    /**
     * @dev See {IERC721Infusable-getWithdrawUnlockTime}.
     */
    function getWithdrawUnlockTime(uint256 tokenId) external view override returns (uint256) {
        require(_exists(tokenId), "ERC721Infusable: nonexistent token");
        return _withdrawLockedUntil[tokenId];
    }

    /**
     * @dev See {IERC721Infusable-maxWithdrawLockWeeks}.
     */
    function maxWithdrawLockWeeks() external view override returns (uint256) {
        return _maxWithdrawLockWeeks;
    }

    /**
     * @dev See {IERC721Infusable-infusedToken}.
     */
    function infusedToken() public view override returns (IERC20) {
        return _erc20Token;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721Infusable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Withdraws {ERC20} tokens from `tokenId` to _msgSender()
     *
     * Requirements:
     *
     * - Cannot withdraw 0 tokens.
     */
    function _tokenWithdraw(uint256 tokenId) internal virtual {
        uint256 erc20TokenQty = _tokenInfusedQty[tokenId];

        require(erc20TokenQty > 0, "ERC721Infusable: cannot withdraw 0 tokens");

        delete _tokenInfusedQty[tokenId];

        infusedToken().safeTransfer(_msgSender(), erc20TokenQty);

        emit TokenWithdraw(_msgSender(), erc20TokenQty, tokenId);
    }

    /**
     * @dev Infuses {ERC20} tokens from _msgSender() to `tokenId`
     *
     * Requirements:
     *
     * - Cannot infuse 0 tokens.
     */
    function _tokenInfuse(uint256 tokenId, uint256 _erc20TokenQty) internal virtual {     
        require(_erc20TokenQty > 0, "ERC721Infusable: cannot infuse 0 tokens");

        _addToInfusedQty(tokenId, _erc20TokenQty);

        infusedToken().safeTransferFrom(msg.sender, address(this), _erc20TokenQty);

        emit TokenInfuse(tokenId, _erc20TokenQty);
    }

    /**
     * @dev Adds `_erc20TokenQty` to '_tokenInfusedQty' mapping for `tokenId`
     * This is a method provided which can allow child contracts limited access
     * to the private '_tokenInfusedQty' mapping.
     *
     */
    function _addToInfusedQty(uint256 tokenId, uint256 _erc20TokenQty) internal virtual {
        _tokenInfusedQty[tokenId] = _tokenInfusedQty[tokenId] + _erc20TokenQty;
    }

    /**
     * @dev Sets a timed withdraw lock for infused {ERC20} tokens.
     *
     * NOTE: This internal function does not check whether the token is already locked.
     * The use of block.timestamp is acceptable in this function as the minimum lock
     * duration is 1 week.
     *
     * Requirements:
     *
     * - `lockWeeks` must not be <= _maxWithdrawLockWeeks
     */
    function _setWithdrawLock(uint256 tokenId, uint256 lockWeeks) internal virtual {
        require(lockWeeks <= _maxWithdrawLockWeeks, "ERC721Infusable: max lock weeks exceeded");

        // solhint-disable-next-line not-rely-on-time
        uint256 unlockTimestamp = block.timestamp + (lockWeeks * 1 weeks);

        _withdrawLockedUntil[tokenId] = unlockTimestamp;

        emit SetWithdrawLock(tokenId, lockWeeks);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - Cannot burn while infused
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        // Token must not be currently infused to burn.
        require(_tokenInfusedQty[tokenId] == 0, "ERC721Infusable: cannot burn while infused");

        // Remove any withdraw locking data for tokenId
        if (_withdrawLockedUntil[tokenId] != 0) {
            delete _withdrawLockedUntil[tokenId];
        }

        super._burn(tokenId);
    }

    /**
     * @dev Hook to allow adding additional logic prior to allowing a token to 
     * be withdrawn.
     */
    function _beforeTokenWithdraw(uint256) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }
}
