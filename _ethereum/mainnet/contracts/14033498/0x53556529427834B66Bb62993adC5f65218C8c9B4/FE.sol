// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract FE is Ownable, IERC721Receiver {
    address private constant ED = 0x0c84298DBaF3B714dD33Bd0D3E3714A8B6648fd2;

    function mint(uint256 iterations) external onlyOwner {
        bytes memory data = abi.encodeWithSignature("safeMint()");
        for (uint256 i; i < iterations; i++) {
            (bool success, ) = ED.call(data);
            require(success);
        }
    }

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        IERC721 sender = IERC721(msg.sender);
        sender.transferFrom(operator, owner(), tokenId);
        return this.onERC721Received.selector;
    }
}
