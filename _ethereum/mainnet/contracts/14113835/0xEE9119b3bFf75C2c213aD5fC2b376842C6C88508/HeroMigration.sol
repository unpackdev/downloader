// SPDX-License-Identifier: MIT

/// @title RaidParty Hero Migration

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./Hero.sol";
import "./IOldHero.sol";
import "./IERC721Receiver.sol";
import "./AccessControlEnumerable.sol";

contract HeroMigration is IERC721Receiver, AccessControlEnumerable {
    Hero public hero;
    IOldHero public oldHero;

    constructor(
        address admin,
        Hero _hero,
        IOldHero _oldHero
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        hero = _hero;
        oldHero = _oldHero;
    }

    receive() external payable {}

    function emergencyBurn(uint256[] calldata tokenIds)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                oldHero.ownerOf(tokenId) == address(this),
                "HeroMigration::emergencyBurn: token is not owned"
            );

            oldHero.burn(tokenId);
        }
    }

    function emergencyTransfer(
        uint256[] calldata tokenIds,
        address[] calldata receivers
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            tokenIds.length == receivers.length,
            "HeroMigration::emergencyTransfer: array length mismatch"
        );
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address receiver = receivers[i];

            hero.safeTransferFrom(address(this), receiver, tokenId);
        }
    }

    function emergencyCall(
        address callee,
        bytes calldata data,
        uint256 value
    )
        external
        payable
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool, bytes memory)
    {
        return callee.call{value: value}(data);
    }

    function manualMigrate(uint256[] calldata tokenIds, bool refund) external {
        uint256 startGas = gasleft();
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            oldHero.transferFrom(msg.sender, address(this), tokenId);
            oldHero.burn(tokenId);

            hero.safeTransferFrom(address(this), msg.sender, tokenId);
        }

        if (refund) {
            uint256 gasUsed = startGas - gasleft() + 21000;
            uint256 gasPrice = tx.gasprice;
            if (gasPrice >= 200 gwei) {
                gasPrice = 200 gwei;
            }

            (bool success, ) = msg.sender.call{value: gasUsed * gasPrice}("");
            require(success, "HeroMigration::manualMigrate: failed to refund");
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        uint256 startGas = gasleft();
        if (msg.sender == address(oldHero)) {
            require(
                tokenId <= 1111,
                "HeroMigration::onERC721Received: invalid tokenId"
            );
            oldHero.burn(tokenId);
            hero.safeTransferFrom(address(this), from, tokenId);

            uint256 gasUsed = startGas - gasleft() + 51000;
            uint256 gasPrice = tx.gasprice;
            if (gasPrice >= 200 gwei) {
                gasPrice = 200 gwei;
            }

            (bool success, ) = operator.call{value: gasUsed * gasPrice}("");
            require(
                success,
                "HeroMigration::onERC721Received: failed to refund"
            );
        }

        return this.onERC721Received.selector;
    }
}
