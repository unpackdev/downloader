// contracts/NFT.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./TimelockController.sol";

contract TokenVault is IERC721Receiver, TimelockController {
    constructor(address[] memory proposers, address[] memory executors) TimelockController(0, proposers, executors) {}

    /**
     * Allow it to send any NFT that it holds. Convenience function
     */
    function sendNFT(
        IERC721 _contractAddress,
        address _recipient,
        uint256 _tokenId
    ) public {
        require(hasRole(EXECUTOR_ROLE, msg.sender), "err: caller does not have executor role");
        _contractAddress.safeTransferFrom(address(this), _recipient, _tokenId);
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function onERC721Received(
        address,
        address,
        bytes memory
    ) public pure returns (bytes4) {
        return 0xf0b9e5ba;
    }
}
