// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IGammaRedeemerV1.sol";
import "./IGammaOperator.sol";
import "./IResolver.sol";
import "./OpynVault.sol";

/// @author Willy Shen
/// @title GammaRedeemer Resolver
/// @notice A GammaRedeemer resolver for Gelato PokeMe checks
contract GammaRedeemerResolver is IResolver {
    address public redeemer;

    constructor(address _redeemer) {
        redeemer = _redeemer;
    }

    /**
     * @notice return if a specific order can be processed
     * @param _orderId id of order
     * @return true if order can be proceseed without a revert
     */
    function canProcessOrder(uint256 _orderId) public view returns (bool) {
        IGammaRedeemerV1.Order memory order = IGammaRedeemerV1(redeemer)
            .getOrder(_orderId);

        if (order.isSeller) {
            if (
                !IGammaOperator(redeemer).isValidVaultId(
                    order.owner,
                    order.vaultId
                ) || !IGammaOperator(redeemer).isOperatorOf(order.owner)
            ) return false;

            (
                MarginVault.Vault memory vault,
                uint256 typeVault,

            ) = IGammaOperator(redeemer).getVaultWithDetails(
                order.owner,
                order.vaultId
            );

            try IGammaOperator(redeemer).getVaultOtoken(vault) returns (
                address otoken
            ) {
                if (
                    !IGammaOperator(redeemer).hasExpiredAndSettlementAllowed(
                        otoken
                    )
                ) return false;

                (uint256 payout, bool isValidVault) = IGammaOperator(redeemer)
                    .getExcessCollateral(vault, typeVault);
                if (!isValidVault || payout == 0) return false;
            } catch {
                return false;
            }
        } else {
            if (
                !IGammaOperator(redeemer).hasExpiredAndSettlementAllowed(
                    order.otoken
                )
            ) return false;
        }

        return true;
    }

    /**
     * @notice return list of processable orderIds
     * @return canExec if gelato should execute
     * @return execPayload the function and data to be executed by gelato
     * @dev order is processable if:
     * 1. it is profitable to process (shouldProcessOrder)
     * 2. it can be processed without reverting (canProcessOrder)
     * 3. it is not included yet (for same type of orders, process it one at a time)
     */
    function getProcessableOrders()
        public
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        IGammaRedeemerV1.Order[] memory orders = IGammaRedeemerV1(redeemer)
            .getOrders();

        // Only proceess duplicate orders one at a time
        bytes32[] memory preCheckHashes = new bytes32[](orders.length);
        bytes32[] memory postCheckHashes = new bytes32[](orders.length);

        uint256 orderIdsLength;
        for (uint256 i = 0; i < orders.length; i++) {
            if (
                IGammaRedeemerV1(redeemer).shouldProcessOrder(i) &&
                canProcessOrder(i) &&
                !containDuplicateOrderType(orders[i], preCheckHashes)
            ) {
                preCheckHashes[i] = getOrderHash(orders[i]);
                orderIdsLength++;
            }
        }

        if (orderIdsLength > 0) {
            canExec = true;
        }

        uint256 counter;
        uint256[] memory orderIds = new uint256[](orderIdsLength);
        for (uint256 i = 0; i < orders.length; i++) {
            if (
                IGammaRedeemerV1(redeemer).shouldProcessOrder(i) &&
                canProcessOrder(i) &&
                !containDuplicateOrderType(orders[i], postCheckHashes)
            ) {
                postCheckHashes[i] = getOrderHash(orders[i]);
                orderIds[counter] = i;
                counter++;
            }
        }

        execPayload = abi.encodeWithSelector(
            IGammaRedeemerV1.processOrders.selector,
            orderIds
        );
    }

    /**
     * @notice return if order is already included
     * @param order struct to check
     * @param hashes list of hashed orders
     * @return containDuplicate if hashes already contain a same order type.
     */
    function containDuplicateOrderType(
        IGammaRedeemerV1.Order memory order,
        bytes32[] memory hashes
    ) public pure returns (bool containDuplicate) {
        bytes32 orderHash = getOrderHash(order);

        for (uint256 j = 0; j < hashes.length; j++) {
            if (hashes[j] == orderHash) {
                containDuplicate = true;
                break;
            }
        }
    }

    /**
     * @notice return hash of the order
     * @param order struct to hash
     * @return orderHash hash depending on the order's type
     */
    function getOrderHash(IGammaRedeemerV1.Order memory order)
        public
        pure
        returns (bytes32 orderHash)
    {
        if (order.isSeller) {
            orderHash = keccak256(abi.encode(order.owner, order.vaultId));
        } else {
            orderHash = keccak256(abi.encode(order.owner, order.otoken));
        }
    }
}
