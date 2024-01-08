// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./UniswapV2Pair.sol";
import "./ERC1155Receiver.sol";

/**
 * RenaswapV1Pair works as a UniswapV2Pair
 * Adds ERC1155Receiver interface used by the wrapper
 */
contract RenaswapV1Pair is UniswapV2Pair, ERC1155Receiver {

    constructor() UniswapV2Pair() ERC1155Receiver() {
    }

    function onERC1155Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*id*/,
        uint256 /*value*/,
        bytes calldata /*data*/
    )
        external override pure
        returns(bytes4) {
            return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
        }

    function onERC1155BatchReceived(
        address /*operator*/,
        address /*from*/,
        uint256[] calldata /*ids*/,
        uint256[] calldata /*values*/,
        bytes calldata /*data*/
    )
        external override pure
        returns(bytes4) {
        }
}