//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./NFTStaking.sol";

/// @notice An ERC721/ERC20 style balanceOf view that sums owned and staked NFTs
contract PlanktoonsBalance {
    IERC721 public immutable nft;
    NFTStaking public immutable staking;

    constructor(IERC721 nft_, NFTStaking staking_) {
        nft = nft_;
        staking = staking_;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return nft.balanceOf(owner) + staking.getStakedBalance(owner);
    }
}
