// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "./MerkleProof.sol";
import "./IERC20.sol";
import "./AppType.sol";
import "./Utils.sol";

library BatchFactory {
    using LeafUtils for AppType.NFT;
    using LeafUtils for AppType.Pass;
    using MerkleProof for bytes32[];

    event BatchCreated(
        uint256 batchId,
        AppType.BatchKind kind,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    );
    event BatchUpdated(
        uint256 batchId,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    );
    event ExcludedLeaf(bytes32 leaf, uint256 batchId, bool isExcluded);
    event AuthorizedMint(
        uint256 nftBatchId,
        uint256 passBatchId,
        string nftUri,
        uint256 tierId,
        address swapToken,
        uint256 swapAmount,
        address account,
        uint256 newTokenId
    );

    function createBatch(
        AppType.State storage state,
        AppType.BatchKind kind,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );
        uint256 newBatchId = ++state.id[AppType.Model.BATCH];
        state.batches[newBatchId] = AppType.Batch({
            id: newBatchId,
            kind: kind,
            isOpenAt: isOpenAt,
            disabled: disabled,
            root: root,
            collection: collection
        });
        emit BatchCreated(
            newBatchId,
            kind,
            isOpenAt,
            disabled,
            root,
            collection
        );
    }

    function updateBatch(
        AppType.State storage state,
        uint256 batchId,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        require(state.batches[batchId].id == batchId, "E001");
        AppType.Batch storage batch = state.batches[batchId];
        batch.isOpenAt = isOpenAt;
        batch.disabled = disabled;
        batch.root = root;
        batch.collection = collection;
        emit BatchUpdated(batchId, isOpenAt, disabled, root, collection);
    }

    function readBatch(AppType.State storage state, uint256 batchId)
        public
        view
        returns (
            AppType.BatchKind kind,
            uint256 isOpenAt,
            bool disabled,
            bytes32 root
        )
    {
        require(state.batches[batchId].id == batchId, "E001");
        return (
            state.batches[batchId].kind,
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
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        bytes32 leaf = nft.nftLeaf(state);
        state.excludedLeaves[leaf] = isExcluded;
        emit ExcludedLeaf(leaf, nft.batchId, isExcluded);
    }

    function excludePassLeaf(
        AppType.State storage state,
        AppType.Pass memory pass,
        bool isExcluded
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        bytes32 leaf = pass.passLeaf(state);
        state.excludedLeaves[leaf] = isExcluded;
        emit ExcludedLeaf(leaf, pass.batchId, isExcluded);
    }

    function authorizeMint(
        AppType.State storage state,
        AppType.NFT memory nft,
        AppType.Pass memory pass,
        AppType.Proof memory proof
    ) public returns (uint256 newTokenId) {
        require(!state.config.bools[AppType.BoolConfig.PAUSED], "E013");

        if (!state.config.bools[AppType.BoolConfig.ALLOW_MINT_WITHOUT_PASS]) {
            AppType.Batch storage passBatch = state.batches[pass.batchId];

            require(
                passBatch.id == pass.batchId &&
                    passBatch.kind == AppType.BatchKind.PASS &&
                    passBatch.isOpenAt <= block.timestamp &&
                    !passBatch.disabled,
                "E002"
            );

            bytes32 passLeaf = pass.passLeaf(state);
            require(state.usedLeaves[passLeaf] < pass.balance, "E003");

            require(proof.pass.verify(passBatch.root, passLeaf), "E004");
            require(state.excludedLeaves[passLeaf] == false, "E005");
            ++state.usedLeaves[passLeaf];
        }

        {
            AppType.Batch storage nftBatch = state.batches[nft.batchId];

            require(
                nftBatch.id == nft.batchId &&
                    nftBatch.kind == AppType.BatchKind.NFT &&
                    nftBatch.isOpenAt <= block.timestamp &&
                    !nftBatch.disabled,
                "E006"
            );

            bytes32 nftLeaf = nft.nftLeaf(state);
            require(state.usedLeaves[nftLeaf] == 0, "E007");
            require(proof.nft.verify(nftBatch.root, nftLeaf), "E008");
            require(state.excludedLeaves[nftLeaf] == false, "E009");
            ++state.usedLeaves[nftLeaf];
        }

        uint256 swapAmount = state.tierSwapAmounts[nft.tierId][nft.swapToken];

        {
            require(swapAmount > 0, "E010");

            if (nft.swapToken == address(0)) {
                require(msg.value >= swapAmount, "E011");
                payable(
                    state.config.addresses[AppType.AddressConfig.FEE_WALLET]
                ).transfer(swapAmount);
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
            pass.batchId,
            nft.uri,
            nft.tierId,
            nft.swapToken,
            swapAmount,
            msg.sender,
            newTokenId
        );
    }
}

// Error Codes

// E001 - Batch not found
// E002 - Pass Batch not found
// E003 - Pass already used
// E004 - Pass not found
// E005 - Pass is excluded
// E006 - NFT Batch not found
// E007 - NFT already Minted
// E008 - NFT not found
// E009 - NFT is excluded
// E010 - swapAmount is 0
// E011 - Insufficient swap amount sent to mint
// E012 - Only DAO can perform this operation
// E013 - Minting is PAUSED
