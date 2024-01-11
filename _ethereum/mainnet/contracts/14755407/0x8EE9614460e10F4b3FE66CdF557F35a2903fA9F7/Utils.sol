// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./AppType.sol";

library LeafUtils {
    function nftLeaf(AppType.NFT memory nft, AppType.State storage state)
        public
        view
        returns (bytes32 leaf)
    {
        leaf = keccak256(
            abi.encode(
                nft.batchId,
                nft.uri,
                nft.royaltyPercent,
                nft.tierId,
                state.config.strings[AppType.StringConfig.APP_NAME],
                state.config.uints[AppType.UintConfig.CHAIN_ID]
            )
        );
        return leaf;
    }
}
