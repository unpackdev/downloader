// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./IERC721Receiver.sol";

contract ERC721ReceiverFacet is IERC721Receiver {
    /// @notice A function to support ERC-721 safeTransferFrom()
    function onERC721Received(
        /* solhint-disable no-unused-vars */
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
        /* solhint-enable no-unused-vars */
    ) external override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
