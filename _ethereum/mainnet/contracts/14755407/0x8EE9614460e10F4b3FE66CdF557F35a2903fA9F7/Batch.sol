// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./MerkleProof.sol";
import "./IERC20.sol";
import "./AppType.sol";
import "./Utils.sol";

library BatchFactory {
    using LeafUtils for AppType.NFT;
    using MerkleProof for bytes32[];

    event BatchCreated(
        uint256 batchId,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root
    );
    event BatchUpdated(
        uint256 batchId,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root
    );
    event ExcludedLeaf(bytes32 leaf, uint256 batchId, bool isExcluded);
    event AuthorizedMint(
        uint256 nftBatchId,
        string nftUri,
        uint256 tierId,
        address swapToken,
        uint256 swapAmount,
        address account,
        uint256 newTokenId
    );

    function createBatch(
        AppType.State storage state,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.ADMIN],
            "E001"
        );
        uint256 newBatchId = ++state.id[AppType.Model.BATCH];
        state.batches[newBatchId] = AppType.Batch({
            id: newBatchId,
            isOpenAt: isOpenAt,
            disabled: disabled,
            root: root
        });
        emit BatchCreated(newBatchId, isOpenAt, disabled, root);
    }

    function updateBatch(
        AppType.State storage state,
        uint256 batchId,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.ADMIN],
            "E001"
        );

        require(state.batches[batchId].id == batchId, "E002");
        AppType.Batch storage batch = state.batches[batchId];
        batch.isOpenAt = isOpenAt;
        batch.disabled = disabled;
        batch.root = root;
        emit BatchUpdated(batchId, isOpenAt, disabled, root);
    }

    function readBatch(AppType.State storage state, uint256 batchId)
        public
        view
        returns (
            uint256 isOpenAt,
            bool disabled,
            bytes32 root
        )
    {
        require(state.batches[batchId].id == batchId, "E002");
        return (
            state.batches[batchId].isOpenAt,
            state.batches[batchId].disabled,
            state.batches[batchId].root
        );
    }

    function excludeNFTLeaf(
        AppType.State storage state,
        AppType.NFT memory nft,
        bool isExcluded
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.ADMIN],
            "E001"
        );

        bytes32 leaf = nft.nftLeaf(state);
        state.excludedLeaves[leaf] = isExcluded;
        emit ExcludedLeaf(leaf, nft.batchId, isExcluded);
    }

    function authorizeMint(
        AppType.State storage state,
        AppType.NFT memory nft,
        uint256 nftAmount,
        bytes32[] memory proof
    ) public returns (uint256 newTokenId) {
        require(!state.config.bools[AppType.BoolConfig.PAUSED], "E011");

        {
            AppType.Batch storage nftBatch = state.batches[nft.batchId];

            require(
                nftBatch.id == nft.batchId &&
                    nftBatch.isOpenAt <= block.timestamp &&
                    !nftBatch.disabled,
                "E003"
            );

            bytes32 nftLeaf = nft.nftLeaf(state);
            require(proof.verify(nftBatch.root, nftLeaf), "E004");
            require(state.excludedLeaves[nftLeaf] == false, "E005");
        }

        uint256 swapAmount = state.tierSwapAmounts[nft.tierId][nft.swapToken];

        swapAmount = swapAmount * nftAmount;

        {
            require(swapAmount > 0, "E006");

            if (nft.swapToken == address(0)) {
                require(msg.value >= swapAmount, "E007");
            } else {
                IERC20(nft.swapToken).transferFrom(
                    msg.sender,
                    state.config.addresses[AppType.AddressConfig.FEE_WALLET],
                    swapAmount
                );
            }
        }

        newTokenId = uint256(keccak256(abi.encode(nft.uri)));

        emit AuthorizedMint(
            nft.batchId,
            nft.uri,
            nft.tierId,
            nft.swapToken,
            swapAmount,
            msg.sender,
            newTokenId
        );
    }
}
