// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC721OldReceiver.sol";

contract ERC721OldHolder is IERC721OldReceiver {
    /**
     * @dev See {IERC721OldReceiver-onERC721Received}.
     *
     * Always returns `IERC721OldReceiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
