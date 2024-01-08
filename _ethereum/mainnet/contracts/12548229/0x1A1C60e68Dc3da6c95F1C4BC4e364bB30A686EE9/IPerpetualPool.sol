// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IMigratablePool.sol";

/**
 * @title Deri Protocol PerpetualPool Interface
 */
interface IPerpetualPool is IMigratablePool {

    /**
     * @dev Emitted when `owner` traded `tradeVolume` at `price` in pool
     */
    event Trade(address indexed owner, int256 tradeVolume, uint256 price);

    /**
     * @dev Emitted when `owner` deposit margin of `bAmount` in base token
     */
    event DepositMargin(address indexed owner, uint256 bAmount);

    /**
     * @dev Emitted when `owner` withdraw margin of `bAmount` in base token
     */
    event WithdrawMargin(address indexed owner, uint256 bAmount);

    /**
     * @dev Emitted when `owner` add liquidity of `bAmount`,
     * and receive `lShares` liquidity token
     */
    event AddLiquidity(address indexed owner, uint256 lShares, uint256 bAmount);

    /**
     * @dev Emitted when `owner` burn `lShares` of liquidity token,
     * and receive `bAmount` in base token
     */
    event RemoveLiquidity(address indexed owner, uint256 lShares, uint256 bAmount);

    /**
     * @dev Emitted when `owner`'s position is liquidated
     */
    event Liquidate(
        address indexed owner,
        int256 volume,
        int256 cost,
        uint256 margin,
        uint256 timestamp,
        uint256 price,
        address liquidator,
        uint256 reward
    );

    /**
     * @dev Initialize pool
     *
     * addresses:
     *      bToken
     *      pToken
     *      lToken
     *      oracle
     *      liquidatorQualifier
     *
     * parameters:
     *      multiplier
     *      feeRatio
     *      minPoolMarginRatio
     *      minInitialMarginRatio
     *      minMaintenanceMarginRatio
     *      minAddLiquidity
     *      redemptionFeeRatio
     *      fundingRateCoefficient
     *      minLiquidationReward
     *      maxLiquidationReward
     *      liquidationCutRatio
     *      priceDelayAllowance
     */
    function initialize(
        string memory symbol_,
        address[5] calldata addresses_,
        uint256[12] calldata parameters_
    ) external;

    /**
     * @dev Returns trading symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns addresses of (bToken, pToken, lToken, oracle) in this pool
     */
    function getAddresses() external view returns (
        address bToken,
        address pToken,
        address lToken,
        address oracle,
        address liquidatorQualifier
    );

    /**
     * @dev Returns parameters of this pool
     */
    function getParameters() external view returns (
        uint256 multiplier,
        uint256 feeRatio,
        uint256 minPoolMarginRatio,
        uint256 minInitialMarginRatio,
        uint256 minMaintenanceMarginRatio,
        uint256 minAddLiquidity,
        uint256 redemptionFeeRatio,
        uint256 fundingRateCoefficient,
        uint256 minLiquidationReward,
        uint256 maxLiquidationReward,
        uint256 liquidationCutRatio,
        uint256 priceDelayAllowance
    );

    /**
     * @dev Returns currents state values of this pool
     */
    function getStateValues() external view returns (
        int256 cumuFundingRate,
        uint256 cumuFundingRateBlock,
        uint256 liquidity,
        int256 tradersNetVolume,
        int256 tradersNetCost
    );

    /**
     * @dev Trade `tradeVolume` with pool while deposit margin of `bAmount` in base token
     * This function is the combination of `depositMargin` and `trade`
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function tradeWithMargin(int256 tradeVolume, uint256 bAmount) external;
    function tradeWithMargin(
        int256 tradeVolume,
        uint256 bAmount,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Trade `tradeVolume` with pool
     *
     * A trader must hold a Position Token (with sufficient margin in PToken)
     * before calling this function
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function trade(int256 tradeVolume) external;
    function trade(
        int256 tradeVolume,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Deposit margin of `bAmount` in base token
     *
     * If trader does not hold position token, a new position token will be minted
     * to trader with supplied margin
     * Otherwise, the position token of trader will be updated with added margin
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function depositMargin(uint256 bAmount) external;
    function depositMargin(
        uint256 bAmount,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Withdraw margin of `bAmount` in base token
     *
     * Trader must hold a position token
     * If trader holds any open position in position token, the left margin after withdraw
     * must be sufficient for the open position
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function withdrawMargin(uint256 bAmount) external;
    function withdrawMargin(
        uint256 bAmount,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Add liquidity of `bAmount` in base token
     *
     * New liquidity provider token will be issued to the provider
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function addLiquidity(uint256 bAmount) external;
    function addLiquidity(
        uint256 bAmount,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Remove `lShares` of liquidity provider token
     *
     * The liquidity provider token will be burned and
     * the corresponding amount in base token will be sent to provider
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function removeLiquidity(uint256 lShares) external;
    function removeLiquidity(
        uint256 lShares,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Liquidate the position owned by `owner`
     * Anyone can call this function to liquidate a position, as long as the liquidation line
     * is touched, the liquidator will be rewarded
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function liquidate(address owner) external;
    function liquidate(
        address owner,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

}
