// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";

contract StakeOG is Ownable, IERC721Receiver, ReentrancyGuard {
    struct StakeStatus {
        uint256 tokenId;
        address owner;
        uint256 end;
    }

    IERC721 public ogPass;
    mapping(uint256 => StakeStatus) public stakes;

    constructor(address og) {
        ogPass = IERC721(og);
    }

    event StakeEvent(address indexed owner, uint256 end, uint256[] tokenIds);
    event UnstakeEvent(address indexed owner, uint256[] tokenIds);

    /**
     * stakeType 0: 15 days,1 : 30 days
     */
    function stake(uint[] calldata tokenIds, uint stakeType)
        public
        nonReentrant
    {
        require(stakeType < 2, "Invalid stake type");
        require(tokenIds.length > 0, "Invalid tokenIds");
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                ogPass.ownerOf(tokenId) == msg.sender,
                "StakeOG: Not owner of token"
            );
            ogPass.safeTransferFrom(msg.sender, address(this), tokenId);
            stakes[tokenId] = StakeStatus(
                tokenId,
                msg.sender,
                block.timestamp + (stakeType == 0 ? 10 days : 18 days)
            );
        }
        emit StakeEvent(msg.sender, block.timestamp + (stakeType == 0 ? 10 days : 18 days), tokenIds);
    }

    function unstake(uint256[] calldata tokenIds) public nonReentrant {
        require(tokenIds.length > 0, "Invalid tokenIds");
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                stakes[tokenId].end < block.timestamp,
                "StakeOG: Stake not ended"
            );
            require(
                stakes[tokenId].owner == msg.sender,
                "StakeOG: Not owner of token"
            );
            delete stakes[tokenId];
            ogPass.safeTransferFrom(address(this), msg.sender, tokenId);
        }
        emit UnstakeEvent(msg.sender, tokenIds);
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
