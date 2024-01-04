// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IMigratablePool.sol";

/**
 * @title Deri Protocol PreMining PerpetualPool Interface
 */
interface IPreMiningPool is IMigratablePool {

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
     * @dev Initialize pool
     *
     * addresses:
     *      bToken
     *      lToken
     *
     * parameters:
     *      minAddLiquidity
     *      redemptionFeeRatio
     */
    function initialize(
        string memory symbol_,
        address[2] calldata addresses_,
        uint256[2] calldata parameters_
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
        address lToken
    );

    /**
     * @dev Returns parameters of this pool
     */
    function getParameters() external view returns (
        uint256 minAddLiquidity,
        uint256 redemptionFeeRatio
    );

    /**
     * @dev Returns currents state values of this pool
     */
    function getStateValues() external view returns (
        uint256 liquidity
    );

    /**
     * @dev Add liquidity of `bAmount` in base token
     *
     * New liquidity provider token will be issued to the provider
     */
    function addLiquidity(uint256 bAmount) external;

    /**
     * @dev Remove `lShares` of liquidity provider token
     *
     * The liquidity provider token will be burned and
     * the corresponding amount in base token will be sent to provider
     */
    function removeLiquidity(uint256 lShares) external;

}
