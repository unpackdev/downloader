// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IAutoGamma.sol";
import "./IGammaOperator.sol";
import "./IResolver.sol";
import "./OpynVault.sol";
import "./IUniswapRouter.sol";

/// @author Willy Shen
/// @title AutoGamma Resolver
/// @notice AutoGamma resolver for Gelato PokeMe checks
contract AutoGammaResolver is IResolver {
    address public redeemer;
    address public uniRouter;

    uint256 public maxSlippage = 50; // 0.5%
    address public owner;

    constructor(address _redeemer, address _uniRouter) {
        redeemer = _redeemer;
        uniRouter = _uniRouter;
        owner = msg.sender;
    }

    function setMaxSlippage(uint256 _maxSlippage) public {
        require(msg.sender == owner && _maxSlippage <= 500); // sanity check max slippage under 5%
        maxSlippage = _maxSlippage;
    }

    /**
     * @notice return if a specific order can be processed
     * @param _orderId id of order
     * @return true if order can be proceseed without a revert
     */
    function canProcessOrder(uint256 _orderId) public view returns (bool) {
        IAutoGamma.Order memory order = IAutoGamma(redeemer).getOrder(_orderId);

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

            try IGammaOperator(redeemer).getVaultOtokenByVault(vault) returns (
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

                if (order.toToken != address(0)) {
                    address collateral = IGammaOperator(redeemer)
                        .getOtokenCollateral(otoken);
                    if (
                        !IAutoGamma(redeemer).isPairAllowed(
                            collateral,
                            order.toToken
                        )
                    ) return false;
                }
            } catch {
                return false;
            }
        } else {
            if (
                !IGammaOperator(redeemer).hasExpiredAndSettlementAllowed(
                    order.otoken
                )
            ) return false;

            if (order.toToken != address(0)) {
                address collateral = IGammaOperator(redeemer)
                    .getOtokenCollateral(order.otoken);
                if (
                    !IAutoGamma(redeemer).isPairAllowed(
                        collateral,
                        order.toToken
                    )
                ) return false;
            }
        }

        return true;
    }

    /**
     * @notice return payout of an order
     * @param _orderId id of order
     * @return payoutToken token address of payout
     * @return payoutAmount amount of payout
     */
    function getOrderPayout(uint256 _orderId)
        public
        view
        returns (address payoutToken, uint256 payoutAmount)
    {
        IAutoGamma.Order memory order = IAutoGamma(redeemer).getOrder(_orderId);

        if (order.isSeller) {
            (
                MarginVault.Vault memory vault,
                uint256 typeVault,

            ) = IGammaOperator(redeemer).getVaultWithDetails(
                order.owner,
                order.vaultId
            );

            address otoken = IGammaOperator(redeemer).getVaultOtokenByVault(
                vault
            );
            payoutToken = IGammaOperator(redeemer).getOtokenCollateral(otoken);

            (payoutAmount, ) = IGammaOperator(redeemer).getExcessCollateral(
                vault,
                typeVault
            );
        } else {
            payoutToken = IGammaOperator(redeemer).getOtokenCollateral(
                order.otoken
            );

            uint256 actualAmount = IGammaOperator(redeemer).getRedeemableAmount(
                order.owner,
                order.otoken,
                order.amount
            );
            payoutAmount = IGammaOperator(redeemer).getRedeemPayout(
                order.otoken,
                actualAmount
            );
        }
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
        IAutoGamma.Order[] memory orders = IAutoGamma(redeemer).getOrders();

        // Only proceess duplicate orders one at a time
        bytes32[] memory preCheckHashes = new bytes32[](orders.length);
        bytes32[] memory postCheckHashes = new bytes32[](orders.length);

        uint256 orderIdsLength;
        for (uint256 i = 0; i < orders.length; i++) {
            if (
                IAutoGamma(redeemer).shouldProcessOrder(i) &&
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


            IAutoGamma.ProcessOrderArgs[] memory orderArgs
         = new IAutoGamma.ProcessOrderArgs[](orderIdsLength);
        for (uint256 i = 0; i < orders.length; i++) {
            if (
                IAutoGamma(redeemer).shouldProcessOrder(i) &&
                canProcessOrder(i) &&
                !containDuplicateOrderType(orders[i], postCheckHashes)
            ) {
                postCheckHashes[i] = getOrderHash(orders[i]);
                orderIds[counter] = i;

                if (orders[i].toToken != address(0)) {
                    // determine amountOutMin for swap
                    (
                        address payoutToken,
                        uint256 payoutAmount
                    ) = getOrderPayout(i);

                    payoutAmount =
                        payoutAmount -
                        ((orders[i].fee * payoutAmount) / 10_000);

                    address[] memory path = new address[](2);
                    path[0] = payoutToken;
                    path[1] = orders[i].toToken;

                    uint256[] memory amounts = IUniswapRouter(uniRouter)
                        .getAmountsOut(payoutAmount, path);
                    uint256 amountOutMin = amounts[1] -
                        ((amounts[1] * maxSlippage) / 10_000);

                    orderArgs[counter].swapAmountOutMin = amountOutMin;
                    orderArgs[counter].swapPath = path;
                }

                counter++;
            }
        }

        execPayload = abi.encodeWithSelector(
            IAutoGamma.processOrders.selector,
            orderIds,
            orderArgs
        );
    }

    /**
     * @notice return if order is already included
     * @param order struct to check
     * @param hashes list of hashed orders
     * @return containDuplicate if hashes already contain a same order type.
     */
    function containDuplicateOrderType(
        IAutoGamma.Order memory order,
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
    function getOrderHash(IAutoGamma.Order memory order)
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
