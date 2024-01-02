// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./LimitOrderLibrary.sol";
import "./PrimexPricingLibrary.sol";
import "./PositionLibrary.sol";

import "./IPositionManagerStorage.sol";
import "./IKeeperRewardDistributor.sol";
import "./IPausable.sol";

interface IPositionManager is IPositionManagerStorage, IPausable {
    struct ClosePositionVars {
        PositionLibrary.Position position;
        bool borrowedAmountIsNotZero;
        uint256 oracleTolerableLimit;
        bool needOracleTolerableLimitCheck;
    }

    event SetMaxPositionSize(address token0, address token1, uint256 amountInToken0, uint256 amountInToken1);
    event SetDefaultOracleTolerableLimit(uint256 indexed oracleTolerableLimit);
    event SecurityBufferChanged(uint256 indexed securityBuffer);
    event MaintenanceBufferChanged(uint256 indexed maintenanceBuffer);
    event SetOracleTolerableLimit(address indexed assetA, address indexed assetB, uint256 oracleTolerableLimit);
    event KeeperRewardDistributorChanged(address indexed _keeperRewardDistributor);
    event MinPositionSizeAndAssetChanged(uint256 indexed _minPositionSize, address indexed _minPositionAsset);
    event OracleTolerableLimitMultiplierChanged(uint256 indexed newMultiplier);

    event OpenPosition(
        uint256 indexed positionId,
        address indexed trader,
        address indexed openedBy,
        PositionLibrary.Position position,
        address feeToken,
        uint256 protocolFee,
        uint256 entryPrice,
        uint256 leverage,
        LimitOrderLibrary.Condition[] closeConditions
    );

    event PartialClosePosition(
        uint256 indexed positionId,
        address indexed trader,
        address bucketAddress,
        address soldAsset,
        address positionAsset,
        uint256 decreasePositionAmount,
        uint256 depositedAmount,
        uint256 scaledDebtAmount,
        int256 profit,
        uint256 positionDebt,
        uint256 amountOut
    );

    event IncreaseDeposit(
        uint256 indexed positionId,
        address indexed trader,
        uint256 depositDelta,
        uint256 scaledDebtAmount
    );

    event DecreaseDeposit(
        uint256 indexed positionId,
        address indexed trader,
        uint256 depositDelta,
        uint256 scaledDebtAmount
    );

    event UpdatePositionConditions(
        uint256 indexed positionId,
        address indexed trader,
        LimitOrderLibrary.Condition[] closeConditions
    );

    /**
     * @notice Initializes the contract with the specified addresses and initializes inherited contracts.
     * @param _registry The address of the Registry contract.
     * @param _primexDNS The address of the PrimexDNS contract.
     * @param _traderBalanceVault The address of the TraderBalanceVault contract.
     * @param _priceOracle The address of the PriceOracle contract.
     * @param _keeperRewardDistributor The address of the KeeperRewardDistributor contract.
     * @param _whiteBlackList The address of the WhiteBlacklist contract.
     */
    function initialize(
        address _registry,
        address _primexDNS,
        address payable _traderBalanceVault,
        address _priceOracle,
        address _keeperRewardDistributor,
        address _whiteBlackList
    ) external;

    /**
     * @notice Sets the maximum position size for a pair of tokens.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _token0 The address of the first token in the pair.
     * @param _token1 The address of the second token in the pair.
     * @param _amountInToken0 The maximum amount of token0 allowed in the position.
     * @param _amountInToken1 The maximum amount of token1 allowed in the position.
     */
    function setMaxPositionSize(
        address _token0,
        address _token1,
        uint256 _amountInToken0,
        uint256 _amountInToken1
    ) external;

    /**
     * @notice Sets the default oracle tolerable limit for the protocol.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _percent The new value for the default oracle tolerable limit. Measured in WAD (1 WAD = 100%).
     */
    function setDefaultOracleTolerableLimit(uint256 _percent) external;

    /**
     * @notice Sets the oracle tolerable limit between two assets.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _assetA The address of the first asset.
     * @param _assetB The address of the second asset.
     * @param _percent The new value for the oracle tolerable limit between two assets. Measured in WAD (1 WAD = 100%).
     */
    function setOracleTolerableLimit(address _assetA, address _assetB, uint256 _percent) external;

    /**
     * @notice Function to set oracleTolerableLimitMultiplier.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param newMultiplier New multiplier in WAD format.
     */
    function setOracleTolerableLimitMultiplier(uint256 newMultiplier) external;

    /**
     * @notice Sets the security buffer value.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * 0 <= newSecurityBuffer < 1.
     * Buffer security parameter is used in calculating the liquidation conditions
     * https://docs.google.com/document/d/1kR8eaqV4289MAbLKgIfKsZ2NgjFpeC0vpVL7jVUTvho/edit#bookmark=id.i9v508hvrv42
     * @param newSecurityBuffer The new value of the security buffer in WAD format.
     */
    function setSecurityBuffer(uint256 newSecurityBuffer) external;

    /**
     * @notice Sets the maintenance buffer value.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * The new maintenance buffer value should be greater than zero and less than one.
     * Maintenance buffer is used in calculating the maximum leverage
     * https://docs.google.com/document/d/1kR8eaqV4289MAbLKgIfKsZ2NgjFpeC0vpVL7jVUTvho/edit#bookmark=id.87oc1j1s9z21
     * @param newMaintenanceBuffer The new value of the maintenance buffer in WAD format.
     */
    function setMaintenanceBuffer(uint256 newMaintenanceBuffer) external;

    /**
     * @notice Sets the address of the SpotTradingRewardDistributor contract.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _spotTradingRewardDistributor The address of the SpotTradingRewardDistributor contract.
     */
    function setSpotTradingRewardDistributor(address _spotTradingRewardDistributor) external;

    /**
     * @notice Sets the KeeperRewardDistributor contract.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _keeperRewardDistributor The address of the KeeperRewardDistributor contract.
     */
    function setKeeperRewardDistributor(IKeeperRewardDistributor _keeperRewardDistributor) external;

    /**
     * @notice Opens a position based on the provided order parameters.
     * @dev Only callable by the LOM_ROLE role.
     * @param _params The parameters for opening a position.
     * @return The total borrowed amount, position amount, position ID, and entry price of the new position.
     */
    function openPositionByOrder(
        LimitOrderLibrary.OpenPositionByOrderParams calldata _params
    ) external returns (uint256, uint256, uint256, uint256);

    /**
     * @notice Opens margin position.
     * @dev Locks trader's collateral in TraderBalanceVault. Takes loan from bucket for deal.
     * Makes swap bucket borrowedAsset amount on '_dex'. Updates rates and indexes in the '_bucket'.
     * Mints debtToken for trader (msg.sender)
     * @param _params The parameters required to open a position.
     */
    function openPosition(PositionLibrary.OpenPositionParams calldata _params) external payable;

    /**
     * @notice Close trader's active position or liquidate risky position.
     * @dev Protocol will fall down (revert) if two conditions occur both:
     * 1. (token1Price + position.depositedAmount).wdiv(positionDebt) will become lower than 1,
     * so position will make loss for Protocol.
     * 2. Not enough liquidity in bucket to pay that loss.
     * @param _id Position id for `msg.sender`.
     * @param _dealReceiver The receiver of the rest of trader's deposit.
     * @param _routes swap routes on dexes
     * @param _amountOutMin minimum allowed amount out for position
     */
    function closePosition(
        uint256 _id,
        address _dealReceiver,
        PrimexPricingLibrary.Route[] memory _routes,
        uint256 _amountOutMin
    ) external;

    /**
     * @notice Closes trader's active position by closing condition
     * @param _id Position id.
     * @param _keeper The address of the keeper or the recipient of the reward.
     * @param _routes An array of routes for executing trades, swap routes on dexes.
     * @param _conditionIndex The index of the condition to be used for closing the position.
     * @param _ccmAdditionalParams Additional params needed for canBeClosed() of the ConditionalClosingManager.
     * @param _closeReason The reason for closing the position.
     */
    function closePositionByCondition(
        uint256 _id,
        address _keeper,
        PrimexPricingLibrary.Route[] calldata _routes,
        uint256 _conditionIndex,
        bytes calldata _ccmAdditionalParams,
        PositionLibrary.CloseReason _closeReason
    ) external;

    /**
     * @notice Allows the trader to partially close a position.
     * @param _positionId The ID of the position to be partially closed.
     * @param _amount The amount of the position asset to be closed from the position.
     * @param _depositReceiver The address where the remaining deposit will be sent.
     * @param _routes The routing information for swapping assets.
     * @param _amountOutMin The minimum amount to be received after swapping, measured in the same decimal format as the position's asset.
     */
    function partiallyClosePosition(
        uint256 _positionId,
        uint256 _amount,
        address _depositReceiver,
        PrimexPricingLibrary.Route[] calldata _routes,
        uint256 _amountOutMin
    ) external;

    /**
     * @notice Updates the position with the given position ID by setting new close conditions.
     * @param _positionId The ID of the position to update.
     * @param _closeConditions An array of close conditions for the position.
     * @dev The caller of this function must be the trader who owns the position.
     * @dev Emits an `UpdatePositionConditions` event upon successful update.
     */
    function updatePositionConditions(
        uint256 _positionId,
        LimitOrderLibrary.Condition[] calldata _closeConditions
    ) external;

    /**
     * @notice Increases the deposit amount for a given position.
     * @param _positionId The ID of the position to increase the deposit for.
     * @param _amount The amount to increase the deposit by.
     * @param _asset The address of the asset to deposit.
     * @param _takeDepositFromWallet A flag indicating whether to make the deposit immediately.
     * @param _routes An array of routes to use for trading.
     * @param _amountOutMin The minimum amount of the output asset to receive from trading.
     */
    function increaseDeposit(
        uint256 _positionId,
        uint256 _amount,
        address _asset,
        bool _takeDepositFromWallet,
        PrimexPricingLibrary.Route[] calldata _routes,
        uint256 _amountOutMin
    ) external;

    /**
     * @notice Decreases the deposit amount for a given position.
     * @param _positionId The ID of the position.
     * @param _amount The amount to decrease the deposit by.
     */
    function decreaseDeposit(uint256 _positionId, uint256 _amount) external;

    /**
     * @notice Sets the minimum position size and the corresponding asset for positions.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _minPositionSize The new minimum position size.
     * @param _minPositionAsset The address of the asset associated with the minimum position size.
     */
    function setMinPositionSize(uint256 _minPositionSize, address _minPositionAsset) external;

    /**
     * @notice Checks if a position can be closed based on a specific condition.
     * @param _positionId The ID of the position.
     * @param _conditionIndex The index of the condition within the position's close conditions.
     * @param _additionalParams Additional parameters required for the condition check.
     * @return A boolean indicating whether the position can be closed.
     */
    function canBeClosed(
        uint256 _positionId,
        uint256 _conditionIndex,
        bytes calldata _additionalParams
    ) external returns (bool);

    /**
     * @notice Deletes a positions by their IDs from a specific bucket for a given traders.
     * @param _ids The IDs of the positions to be deleted.
     * @param _traders The addresses of the traders who owns the position.
     * @param _length The length of the traders array.
     * @param _bucket The address of the bucket from which the position is to be deleted.
     */
    function deletePositions(
        uint256[] calldata _ids,
        address[] calldata _traders,
        uint256 _length,
        address _bucket
    ) external;

    /**
     * @notice Transfers a specified amount of tokens from the contract to a specified address.
     * @dev Only callable by the BATCH_MANAGER_ROLE role.
     * @param _token The address of the token to be transferred.
     * @param _to The address to which the tokens will be transferred.
     * @param _amount The amount of tokens to be transferred.
     */
    function doTransferOut(address _token, address _to, uint256 _amount) external;

    /**
     * @notice Returns the oracle tolerable limit for the given asset pair.
     * @param assetA The address of the first asset in the pair.
     * @param assetB The address of the second asset in the pair.
     * @return The oracle tolerable limit in WAD format (1 WAD = 100%) for the asset pair.
     */
    function getOracleTolerableLimit(address assetA, address assetB) external view returns (uint256);

    /**
     * @notice Retrieves the position information for a given ID.
     * @param _id The ID of the position to retrieve.
     * @return position The position information associated with the given ID.
     */
    function getPosition(uint256 _id) external view returns (PositionLibrary.Position memory);

    /**
     * @notice Retrieves the position at the specified index.
     * @param _index The index of the position to retrieve.
     * @return The Position struct at the specified index.
     */
    function getPositionByIndex(uint256 _index) external view returns (PositionLibrary.Position memory);

    /**
     * @notice Returns the length of the positions array.
     * @return The length of the positions array.
     */
    function getAllPositionsLength() external view returns (uint256);

    /**
     * @notice Returns the length of the array containing the positions of a specific trader.
     * @param _trader The address of the trader.
     * @return The number of positions the trader has.
     */
    function getTraderPositionsLength(address _trader) external view returns (uint256);

    /**
     * @notice Returns the length of the array containing the positions of a specific bucket.
     * @param _bucket The address of the bucket.
     * @return The number of positions the bucket has.
     */
    function getBucketPositionsLength(address _bucket) external view returns (uint256);

    /**
     * @notice Returns the debt of a position with the given ID.
     * @param _id The ID of the position.
     * @return The debt of the position, measured in the same decimal format as debtTokens.
     */
    function getPositionDebt(uint256 _id) external view returns (uint256);

    /**
     * @notice Retrieves the close conditions for a specific position.
     * @param _positionId The ID of the position.
     * @return An array of close conditions associated with the position.
     */
    function getCloseConditions(uint256 _positionId) external view returns (LimitOrderLibrary.Condition[] memory);

    /**
     * @notice Retrieves the close condition for a given position and index.
     * @param _positionId The identifier of the position.
     * @param _index The index of the close condition.
     * @return The close condition at the specified position and index.
     */
    function getCloseCondition(
        uint256 _positionId,
        uint256 _index
    ) external view returns (LimitOrderLibrary.Condition memory);

    /**
     * @notice Сhecks if the position is risky.
     * @param _id the id of the position
     * @return (1) True if position is risky
     */
    function isPositionRisky(uint256 _id) external view returns (bool);

    /**
     * @notice Checks if a position with the given ID is delisted.
     * @param _id The ID of the position.
     * @return A boolean indicating whether the position is delisted or not.
     */
    function isDelistedPosition(uint256 _id) external view returns (bool);

    /**
     * @notice Retrieves the health value of a position.
     * @param _id The ID of the position.
     * @return The health value of the position in WAD format.
     */
    function healthPosition(uint256 _id) external view returns (uint256);
}
