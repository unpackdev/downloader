/*
 * Copyright ©️ 2021 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2021 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";

contract ERC721Wrapper is ERC721Enumerable, ReentrancyGuard {
    /**
     * @dev Returns the address of underlying ERC721.
     */
    IERC721URIStorage public underlyingERC721;

    event  Deposit(address indexed user, uint256 tokenId);
    event  Withdrawal(address indexed user, uint256 tokenId);

    constructor(
        IERC721URIStorage underlyingERC721_,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        require(address(underlyingERC721_) != address(0), "ERC721Wrapper: underlyingERC721_ cannot be zero");

        underlyingERC721 = underlyingERC721_;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return underlyingERC721.tokenURI(tokenId);
    }

    /**
     * @dev Deposits/wraps `tokenId` of underlying token.
     */
    function deposit(uint256 tokenId) external nonReentrant {
        underlyingERC721.transferFrom(
            address(msg.sender),
            address(this),
            tokenId
        );

        _mint(address(msg.sender), tokenId);

        emit Deposit(address(msg.sender), tokenId);
    }

    /**
     * @dev Withdraws/unwraps `tokenId` of underlying token.
     */
    function withdraw(uint256 tokenId) external nonReentrant {
        _withdraw(address(msg.sender), tokenId);
    }

    function _withdraw(address account, uint256 tokenId) internal {
        require(_isApprovedOrOwner(account, tokenId), "ERC721Wrapper: caller is not owner nor approved");

        _burn(tokenId);

        underlyingERC721.transferFrom(
            address(this),
            account,
            tokenId
        );

        emit Withdrawal(account, tokenId);
    }
}
