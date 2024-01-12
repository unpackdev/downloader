/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./Address.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IDiamondFacet.sol";
import "./RoleManagerLib.sol";
import "./arteQCollectionV2Config.sol";
import "./TokenStoreLib.sol";
import "./ERC721Internal.sol";

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk
contract ERC721Facet is IDiamondFacet {

    using Address for address;

    modifier onlyAdmin() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getVersion()
      external pure override returns (string memory) {
        return "0.0.1";
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return
            interfaceId == type(IDiamondFacet).interfaceId ||
            interfaceId == type(IERC721).interfaceId;
    }

    function setERC721Settings(
        string memory name_,
        string memory symbol_
    ) external onlyAdmin {
        ERC721Internal._setERC721Settings(name_, symbol_);
    }

    // Most of the code is copied from:
    //   https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol

    function balanceOf(address owner) external view returns (uint256) {
        return ERC721Internal._balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return ERC721Internal._ownerOf(tokenId);
    }

    function name() external view returns (string memory) {
        return ERC721Internal._getName();
    }

    function setName(string memory name_) external onlyAdmin {
        ERC721Internal._setName(name_);
    }

    function symbol() external view returns (string memory) {
        return ERC721Internal._getSymbol();
    }

    function setSymbol(string memory symbol_) external onlyAdmin {
        ERC721Internal._setSymbol(symbol_);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(ERC721Internal._exists(tokenId), "ERC721F:NET");
        return TokenStoreLib._getTokenURI(tokenId);
    }

    function approve(address to, uint256 tokenId) external {
        address owner = ERC721Internal._ownerOf(tokenId);
        require(to != owner, "ERC721F:ATC");
        require(
            msg.sender == owner || ERC721Internal._isApprovedForAll(owner, msg.sender),
            "ERC721F:NO"
        );
        ERC721Internal._approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return ERC721Internal._getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        ERC721Internal._setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return ERC721Internal._isApprovedForAll(owner, operator);
    }

    function transferFromMe(
        address to,
        uint256 tokenId
    ) external onlyAdmin {
        ERC721Internal._transferFromMe(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ERC721Internal._isApprovedOrOwner(msg.sender, tokenId),
                "ERC721F:NO");
        ERC721Internal._transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        require(ERC721Internal._isApprovedOrOwner(msg.sender, tokenId),
                "ERC721F:NO");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        ERC721Internal._transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721F:BADTO");
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721F:BADTO");
                } else {
                    /* solhint-disable no-inline-assembly */
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                    /* solhint-enable no-inline-assembly */
                }
            }
        } else {
            return true;
        }
    }
}
