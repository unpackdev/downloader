// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "./ERC1155TokenReceiver.sol";
import "./ERC721TokenReceiver.sol";
import "./ERC777TokensRecipient.sol";
import "./IERC165.sol";

/**
 * @title OurIntrospector
 * @author Nick A.
 * https://github.com/ourz-network/our-contracts
 *
 * These contracts enable creators, builders, & collaborators of all kinds
 * to receive royalties for their collective work, forever.
 *
 * Thank you,
 * @author Mirror       @title Splits   https://github.com/mirror-xyz/splits
 * @author Gnosis       @title Safe     https://github.com/gnosis/safe-contracts
 * @author OpenZeppelin                 https://github.com/OpenZeppelin/openzeppelin-contracts
 * @author Zora                         https://github.com/ourzora
 */

contract OurIntrospector is
    ERC1155TokenReceiver,
    ERC777TokensRecipient,
    ERC721TokenReceiver,
    IERC165
{
    //======== ERC721 =========
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC721/IERC721Receiver.sol

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0x150b7a02;
    }

    //======== IERC1155 =========
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC1155/IERC1155Receiver.sol

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xbc197c81;
    }

    //======== IERC777 =========
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC777/IERC777Recipient.sol
    //sol
    // solhint-disable-next-line ordering
    event ERC777Received(
        address operator,
        address from,
        address to,
        uint256 amount
    );

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata,
        bytes calldata
    ) external override {
        emit ERC777Received(operator, from, to, amount);
    }

    //======== IERC165 =========
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/introspection/ERC165.sol
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(ERC1155TokenReceiver).interfaceId ||
            interfaceId == type(ERC721TokenReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
