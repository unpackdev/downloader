
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";

contract V3PositionLock is IERC721Receiver, Ownable {
    uint256 public lockTime;
    address public nftAddress = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    event LockNFT(uint256 tokenId,address user);
    event UnlockNFT(uint256 tokenId,address user);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory 
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function lockNFT(uint256 tokenId) external onlyOwner {
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        if (lockTime==0) {
            lockTime = block.timestamp + 3600*24*180;
        }

        emit LockNFT(tokenId, msg.sender);
    }

    function unlockNFT(uint256 tokenId) external onlyOwner {
        require(lockTime > 0 && lockTime < block.timestamp, "LOCK: lock time");

        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        emit UnlockNFT(tokenId, msg.sender);
    }
}