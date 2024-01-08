// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MagicLampWalletEvents {
    event MagicLampWalletSupported(
        address indexed host
    );

    event MagicLampWalletUnsupported(
        address indexed host
    );

    event MagicLampWalletSwapChanged(
        address indexed previousMagicLampSwap,
        address indexed newMagicLampSwap
    );

    event MagicLampWalletLocked(
        address indexed owner,
        address indexed host,
        uint256 id,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    event MagicLampWalletOpened(
        address indexed owner,
        address indexed host,
        uint256 id
    );

    event MagicLampWalletClosed(
        address indexed owner,
        address indexed host,
        uint256 id
    );

    event MagicLampWalletETHDeposited(
        address indexed owner,
        address indexed host,
        uint256 id,
        uint256 amount
    );

    event MagicLampWalletETHWithdrawn(
        address indexed owner,
        address indexed host,
        uint256 id,
        uint256 amount,
        address to
    );

    event MagicLampWalletETHTransferred(
        address indexed owner,
        address indexed host,
        uint256 id,
        uint256 amount,
        address indexed toHost,
        uint256 toId
    );

    event MagicLampWalletERC20Deposited(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc20Token,
        uint256 amount
    );

    event MagicLampWalletERC20Withdrawn(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc20Token,
        uint256 amount,
        address to
    );

    event MagicLampWalletERC20Transferred(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc20Token,
        uint256 amount,
        address indexed toHost,
        uint256 toId
    );

    event MagicLampWalletERC721Deposited(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc721Token,
        uint256 erc721TokenId
    );

    event MagicLampWalletERC721Withdrawn(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc721Token,
        uint256 erc721TokenId,
        address to
    );

    event MagicLampWalletERC721Transferred(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc721Token,
        uint256 erc721TokenId,
        address indexed toHost,
        uint256 toId
    );

    event MagicLampWalletERC1155Deposited(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint256 amount
    );

    event MagicLampWalletERC1155Withdrawn(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint256 amount,
        address indexed to
    );

    event MagicLampWalletERC1155Transferred(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint256 amount,
        address indexed toHost,
        uint256 toId
    );

    event MagicLampWalletERC20Swapped(
        address indexed owner,
        address indexed host,
        uint256 id,
        address inToken,
        uint256 inAmount,
        address outToken,
        uint256 outAmount,
        address indexed to
    );

    event MagicLampWalletERC721Swapped(
        address indexed owner,
        address indexed host,
        uint256 id,
        address inToken,
        uint256 inTokenId,
        address outToken,
        uint256 outTokenId,
        address indexed to
    );

    event MagicLampWalletERC1155Swapped(
        address indexed owner,
        address indexed host,
        uint256 id,
        address inToken,
        uint256 inTokenId,
        uint256 inAmount,
        address outToken,
        uint256 outTokenId,
        uint256 outTokenAmount,
        address indexed to
    );
    
}