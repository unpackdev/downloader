// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IPendle.sol";

/**
 * @title Dollet IPendleStrategy
 * @author Dollet Team
 * @notice Contains methods signatures, events, and structure only for PendleStrategy strategy.
 */
interface IPendleStrategy {
    /**
     * @notice Strategy initialization paramters structure.
     * @param adminStructure AdminStructure contract address.
     * @param strategyHelper A helper contract address used in every strategy.
     * @param feeManager FeeManager contract address.
     * @param weth WETH token contract address.
     * @param want Token address to be deposited in the underlying protocol.
     * @param calculations Calculations contracy address.
     * @param pendleRouter Address of the Pendle router.
     * @param pendleMarket Address of the Pendle market.
     * @param twapPeriod Time-weighted average price (TWAP) period for oracle calculations.
     * @param tokensToCompound An array of the tokens to set the minimum to compound.
     * @param minimumsToCompound An array of the minimum amounts to compound.
     */
    struct InitParams {
        address adminStructure;
        address strategyHelper;
        address feeManager;
        address weth;
        address want;
        address calculations;
        address pendleRouter;
        address pendleMarket;
        uint32 twapPeriod;
        address[] tokensToCompound;
        uint256[] minimumsToCompound;
    }

    /**
     * @notice Sets the TWAP period to be used in the pendle oracle.
     */
    function setTwapPeriod(uint32 _newTwapPeriod) external;

    /**
     * @notice Returns the balance of the strategy held in the strategy or in the underlying protocols.
     * @return The balance of the strategy.
     */
    function balance() external view returns (uint256);

    /**
     * @notice Retrieves information about pending rewards to compound.
     * @param _rewardData Encoded bytes with information about the reward tokens
     * @return _rewardAmounts Rewards amounts representing pending rewards.
     * @return _rewardTokens Addresses of the reward tokens.
     * @return _enoughRewards List indicating if the reward token is enough to compound.
     * @return _atLeastOne Indicates if there is at least one reward to compound.
     */
    function getPendingToCompound(bytes calldata _rewardData)
        external
        view
        returns (
            uint256[] memory _rewardAmounts,
            address[] memory _rewardTokens,
            bool[] memory _enoughRewards,
            bool _atLeastOne
        );

    /**
     * @notice Returns the address of the PendleRouter.
     * @return The address of the PendleRouter.
     */
    function pendleRouter() external view returns (IRouter);

    /**
     * @notice Returns the address of the PendleMarket.
     * @return The address of the PendleMarket.
     */
    function pendleMarket() external view returns (IMarket);

    /**
     * @notice Returns the address of the target asset used to re-deposit.
     * @return The address of the target token that is reinvested.
     */
    function targetAsset() external view returns (address);

    /**
     * @notice Returns the TWAP period used in the pendle oracle.
     * @return The time in seconds to use for the TWAP.
     */
    function twapPeriod() external view returns (uint32);
}
