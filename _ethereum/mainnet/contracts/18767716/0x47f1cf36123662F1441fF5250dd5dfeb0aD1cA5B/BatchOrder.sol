// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title BatchOrder
 * @notice This library contains batch order types for the polsmarket.wtf inscriptions exchange.
 */
library BatchOrder {
    bytes32 internal constant ETHSCRIPTION_BUNDLES_ORDER_HASH =
        keccak256(
            "EthscriptionOrder(address signer,address creator,bytes32[] ethscriptionIds,uint256[] quantities,address currency,uint256 price,uint256 nonce,uint64 startTime,uint64 endTime,uint16 protocolFeeDiscounted,uint16 creatorFee,bytes params)"
        );

    bytes32 internal constant ETHSCRIPTION_SINGLE_ORDER_HASH =
        keccak256(
            "EthscriptionOrder(address signer,address creator,bytes32 ethscriptionId,uint256 quantity,address currency,uint256 price,uint256 nonce,uint64 startTime,uint64 endTime,uint16 protocolFeeDiscounted,uint16 creatorFee,bytes params)"
        );

    struct EthscriptionOrder {
        address signer; // signer of the ethscription seller
        address creator; // deployer of the ethscription collection
        bytes32[] ethscriptionIds; // ethscription bundles
        uint256[] quantities; // if the ethscription is nft: 1, else if is ft: >= 1
        address currency; // currency (e.g., ETH)
        uint256 price; // price
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint64 startTime; // startTime in timestamp
        uint64 endTime; // endTime in timestamp
        uint16 protocolFeeDiscounted; // with some rights and interests, the protocol fee can be discounted, default: 0
        uint16 creatorFee;
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    function bundleHash(EthscriptionOrder memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ETHSCRIPTION_BUNDLES_ORDER_HASH,
                    order.signer,
                    order.creator,
                    keccak256(abi.encodePacked(order.ethscriptionIds)),
                    keccak256(abi.encodePacked(order.quantities)),
                    order.currency,
                    order.price,
                    order.nonce,
                    order.startTime,
                    order.endTime,
                    order.protocolFeeDiscounted,
                    order.creatorFee,
                    keccak256(order.params)
                )
            );
    }

    function singleHash(EthscriptionOrder memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ETHSCRIPTION_SINGLE_ORDER_HASH,
                    order.signer,
                    order.creator,
                    order.ethscriptionIds[0],
                    order.quantities[0],
                    order.currency,
                    order.price,
                    order.nonce,
                    order.startTime,
                    order.endTime,
                    order.protocolFeeDiscounted,
                    order.creatorFee,
                    keccak256(order.params)
                )
            );
    }

    enum MerkleTreeNodePosition {
        Left,
        Right
    }

    /**
     * @notice MerkleTreeNode is a MerkleTree's node.
     * @param value It can be an order hash or a proof
     * @param position The node's position in its branch. It can be left or right or none(before the tree is sorted).
     */
    struct MerkleTreeNode {
        bytes32 value;
        MerkleTreeNodePosition position;
    }

    /**
     * @notice MerkleTree is the struct for a merkle tree of order hashes.
     * @dev A Merkle tree can be computed with order hashes.
     *      It can contain order hashes from both maker bid and maker ask structs.
     * @param root Merkle root
     * @param proof Array containing the merkle proof
     */
    struct MerkleTree {
        bytes32 root;
        MerkleTreeNode[] proof;
    }
}
