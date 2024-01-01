// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface INonfungiblePositionManager {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract NFTRiumLPLocker is IERC721Receiver {
    INonfungiblePositionManager public positionManager;
    uint256 public constant LOCK_PERIOD = 365 days;
    mapping(uint256 => uint256) public unlockTimes;

    constructor(INonfungiblePositionManager nonfungiblePositionManager) {
        positionManager = nonfungiblePositionManager;
    }

    function lockTokens(uint256 tokenId) external {
        require(unlockTimes[tokenId] + LOCK_PERIOD < block.timestamp, "LP is already locked");

        unlockTimes[tokenId] = block.timestamp + LOCK_PERIOD;
        positionManager.transferFrom(msg.sender, address(this), tokenId);
    }

    function unlockTokens(uint256 tokenId) external {
        require(unlockTimes[tokenId] <= block.timestamp, "LP can't be unlocked yet");

        delete unlockTimes[tokenId];
        positionManager.transferFrom(address(this), msg.sender, tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}