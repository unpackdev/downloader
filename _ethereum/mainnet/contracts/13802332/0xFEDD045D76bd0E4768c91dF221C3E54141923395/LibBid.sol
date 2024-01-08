// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library LibBid {
    bytes32 private constant BID_TYPE =
        keccak256(
            "Bid(address userWallet,uint256 amount,address assetContract,uint256 tokenId)"
        );

    struct Bid {
        address userWallet;
        uint256 amount;
        address assetContract;
        uint256 tokenId;
    }

    function bidHash(Bid memory userBid) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BID_TYPE,
                    userBid.userWallet,
                    userBid.amount,
                    userBid.assetContract,
                    userBid.tokenId
                )
            );
    }
}
