// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721Receiver Interface
 *
 * @dev Interface of the ERC721Receiver according to the EIP
 */
interface ERC721Receiver {
    /**
     * @dev ERC721Receiver standard functions
     */

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}
