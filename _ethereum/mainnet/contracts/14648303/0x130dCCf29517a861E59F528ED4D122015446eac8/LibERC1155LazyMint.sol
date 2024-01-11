// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./LibRoyalty.sol";

library LibERC1155LazyMint {
    struct Mint1155Data {
        uint256 tokenId;
        address creator;
        LibRoyalty.Royalty royalty;
        bytes signature;
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH =
        keccak256(
            "Mint1155(uint256 tokenId,address creator,Royalty royalty)Royalty(address account,uint96 value)"
        );

    function hash(Mint1155Data memory data) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MINT_AND_TRANSFER_TYPEHASH,
                    data.tokenId,
                    data.creator,
                    LibRoyalty.hash(data.royalty)
                )
            );
    }
}
