// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * @title Admin Interface
 * @author JieLi
 *
 * @notice Admin Interface
 */
interface IAdmin {

    // ============ Events ============

    event UpdatePrice(uint256 indexed oldPrice, uint256 indexed newPrice);

    event UpdatePresalePrice(uint256 indexed oldPrice, uint256 indexed newPrice);

    event UpdateRevealURI(string indexed oldRevealURI, string indexed newRevealURI);

    event UpdatePendingURI(string indexed oldPendingURI, string indexed newPendingURI);

    event UpdateURIExtension(string indexed oldURIExtension, string indexed newURIExtension);

    event UpdateMaxMintCount(uint256 indexed oldMaxMintCount, uint256 indexed newMaxMintCount);

    event UpdatePresaleCount(uint256 indexed oldPresaleCount, uint256 indexed newPresaleCount);

    event UpdateWhiteListCount(uint256 indexed oldWhiteListCount, uint256 indexed newWhiteListCount);

}
