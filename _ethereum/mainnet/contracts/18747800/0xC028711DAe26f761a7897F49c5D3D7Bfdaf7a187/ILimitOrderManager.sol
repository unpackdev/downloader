// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./LimitOrderLibrary.sol";
import "./PrimexPricingLibrary.sol";

import "./ILimitOrderManagerStorage.sol";
import "./IPausable.sol";

interface ILimitOrderManager is ILimitOrderManagerStorage, IPausable {
    enum LimitOrderType {
        Margin,
        Spot,
        Swap
    }

    struct UpdateOrderConditionsParams {
        uint256 orderId;
        LimitOrderLibrary.Condition[] openConditions;
        LimitOrderLibrary.Condition[] closeConditions;
    }

    event CreateLimitOrder(
        uint256 indexed orderId,
        address indexed trader,
        LimitOrderLibrary.LimitOrder order,
        LimitOrderLibrary.Condition[] openConditions,
        LimitOrderLibrary.Condition[] closeConditions
    );

    event CloseLimitOrder(
        uint256 indexed orderId,
        address indexed trader,
        address indexed closedBy,
        LimitOrderLibrary.CloseReason reason,
        uint256 positionId,
        // TODO: can delete args below when front be ready for it
        string bucket,
        address borrowedAsset,
        address positionAsset,
        uint256 leverage,
        address depositAsset,
        uint256 depositAmount
    );

    event UpdateOrder(
        uint256 indexed orderId,
        address indexed trader,
        uint256 depositAmount,
        uint256 leverage,
        address feeToken,
        uint256 protocolFee
    );

    event UpdateOrderConditions(
        uint256 indexed orderId,
        address indexed trader,
        LimitOrderLibrary.Condition[] openConditions,
        LimitOrderLibrary.Condition[] closeConditions
    );

    /**
     * @notice Initializes the LimitOrderManager contract.
     * @param _registry The address of the Registry contract.
     * @param _primexDNS The address of the PrimexDNS contract.
     * @param _pm The address of the PositionManager contract.
     * @param _traderBalanceVault The address of the TraderBalanceVault contract.
     * @param _swapManager The address of the SwapManager contract.
     * @param _whiteBlackList The address of the WhiteBlacklist contract.
     */
    function initialize(
        address _registry,
        address _primexDNS,
        address _pm,
        address payable _traderBalanceVault,
        address _swapManager,
        address _whiteBlackList
    ) external;

    /**
     * @notice Creates a limit order.
     * @dev This function allows users to create a limit order and locks the deposit asset in the traderBalanceVault
     * @param _params The parameters necessary to create limit order
     */
    function createLimitOrder(LimitOrderLibrary.CreateLimitOrderParams calldata _params) external payable;

    /**
     * @notice Cancels the order. Can only be called by the trader
     * @param _orderId order id
     */
    function cancelLimitOrder(uint256 _orderId) external;

    /**
     * @notice Removes expired limit orders
     * @param _orderIds The array of order IDs to remove.
     */
    function cancelExpiredLimitOrders(uint256[] calldata _orderIds) external;

    /**
     * @notice Opens a position by an existing order.
     * @dev This function is called to open a position based on the given order parameters.
     * @param _params The OpenPositionParams struct containing the necessary parameters for opening the position.
     */
    function openPositionByOrder(LimitOrderLibrary.OpenPositionParams calldata _params) external;

    /**
     * @notice Updates an existing limit order.
     * @dev Edits prices on an existing order
     * @param _params The parameters for updating the limit order.
     */
    function updateOrder(LimitOrderLibrary.UpdateLimitOrderParams calldata _params) external payable;

    /**
     * @notice Updates the open and close conditions of an order.
     * @dev Only the trader of the order can update the conditions.
     * @param _params The parameters for updating the order conditions.
     */
    function updateOrderConditions(UpdateOrderConditionsParams memory _params) external;

    /**
     * @notice Returns true if current price >= limit price and block.timestamp <= deadline
     * @param _orderId order id
     * @param _conditionIndex index of condition in openConditions
     * @param _additionalParams parameters needed for dex
     */
    function canBeFilled(
        uint256 _orderId,
        uint256 _conditionIndex,
        bytes calldata _additionalParams
    ) external returns (bool);

    /**
     * @notice Function to set new swapManager.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _swapManager Address of the new swapManager.
     */
    function setSwapManager(address _swapManager) external;

    /**
     * @notice Retrieves the details of a limit order based on its ID.
     * @param _id The ID of the limit order to retrieve.
     * @return The LimitOrder struct representing the limit order.
     */
    function getOrder(uint256 _id) external view returns (LimitOrderLibrary.LimitOrder memory);

    /**
     * @notice Retrieves the limit order at the specified index.
     * @param _index The index of the limit order to retrieve.
     * @return The limit order at the specified index.
     */
    function getOrderByIndex(uint256 _index) external view returns (LimitOrderLibrary.LimitOrder memory);

    /**
     * @notice Retrieves the close conditions associated with the given order ID.
     * @param _orderId The ID of the order.
     * @return An array of Condition representing the close conditions.
     */
    function getCloseConditions(uint256 _orderId) external view returns (LimitOrderLibrary.Condition[] memory);

    /**
     * @notice Retrieves the open conditions associated with a given order ID.
     * @param _orderId The ID of the order.
     * @return An array of Condition structs representing the open conditions.
     */
    function getOpenConditions(uint256 _orderId) external view returns (LimitOrderLibrary.Condition[] memory);

    /**
     * @notice Returns the length of the orders array.
     * @return The number of orders in the array.
     */
    function getOrdersLength() external view returns (uint256);

    /**
     * @notice Returns the length of the order array for a specific trader.
     * @param _trader The address of the trader.
     * @return The length of the order array.
     */
    function getTraderOrdersLength(address _trader) external view returns (uint256);

    /**
     * @notice Returns an array of LimitOrder structures representing the orders placed by a specific trader.
     * @param _trader The address of the trader.
     * @return traderOrders An array of LimitOrder structures representing the orders placed by the trader.
     */
    function getTraderOrders(address _trader) external view returns (LimitOrderLibrary.LimitOrder[] memory);

    /**
     * @notice Returns the length of orders in a bucket.
     * @param _bucket The address of the bucket.
     * @return The number of orders in the bucket.
     */
    function getBucketOrdersLength(address _bucket) external view returns (uint256);

    /**
     * @notice Retrieves all limit orders associated with a given bucket.
     * @param _bucket The address of the bucket.
     * @return An array of LimitOrder structs representing the bucket's orders.
     */
    function getBucketOrders(address _bucket) external view returns (LimitOrderLibrary.LimitOrder[] memory);
}
