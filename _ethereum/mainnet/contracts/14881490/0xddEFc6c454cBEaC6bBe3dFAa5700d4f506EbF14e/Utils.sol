// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

/*
 * This is 1-on-1 mapping from opensea example
 * https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/ERC721Tradable.sol
 * Retaining contract structure for readability
 */

contract OwnableDelegateProxy {

}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
