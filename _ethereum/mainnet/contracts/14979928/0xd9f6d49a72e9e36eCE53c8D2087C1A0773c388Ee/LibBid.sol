// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @dev Bid Struct definition used to validate EIP712.
 *
 */
library LibBid {
    bytes32 private constant BID_TYPE =
        keccak256(
            "Bid(address winnerWallet,address tokenContract,uint256 tokenIdentifier,uint256 tokenRegistryId,uint256 amount)"
        );

    struct Bid {
        address winnerWallet;
        address tokenContract;
        uint256 tokenIdentifier;
        uint256 tokenRegistryId;
        uint256 amount;
    }

    function bidHash(Bid memory bid) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BID_TYPE,
                    bid.winnerWallet,
                    bid.tokenContract,
                    bid.tokenIdentifier,
                    bid.tokenRegistryId,
                    bid.amount
                )
            );
    }
}
