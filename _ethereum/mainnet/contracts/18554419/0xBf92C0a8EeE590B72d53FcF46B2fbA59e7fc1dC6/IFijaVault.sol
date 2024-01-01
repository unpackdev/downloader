// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IFijaERC4626Base.sol";
import "./IFijaStrategy.sol";

/// @title Vault interface
/// @author Fija
/// @notice Defines interface methods and events used by the FijaVault
///
interface IFijaVault is IFijaERC4626Base {
    ///
    /// @param strategyCandidate address of strategy candidate
    /// @param timestamp proposed time in seconds from when strategy candidate could be
    /// eligble to be promoted to vault strategy. Also depens on IFijaVault.approvalDelay
    ///
    struct StrategyCandidate {
        address implementation;
        uint64 proposedTime;
    }

    ///
    /// @dev emits when new strategy is proposed
    /// @param strategyCandidate address representing StrategyCandidate
    /// @param timestamp time in seconds event is triggered
    ///
    event NewStrategyCandidateEvent(
        address strategyCandidate,
        uint256 timestamp
    );

    ///
    /// @dev emits when strategy canidate has become new vault strategy
    /// @param newStrategy address representing new strategy (IStrategy)
    /// @param timestamp time in seconds when event is triggered
    ///
    event UpdateStrategyEvent(address newStrategy, uint256 timestamp);

    ///
    /// @dev gets strategy in use
    /// @return strategy address
    ///
    function strategy() external view returns (address);

    ///
    /// @dev gets strategy candidate, which has potential to be elected as vault strategy
    /// @return StrategyCandidate object, see IFijaVault.StrategyCandidate
    ///
    function proposedStrategy()
        external
        view
        returns (StrategyCandidate memory);

    ///
    /// @dev gets time which need to pass in order for strategy candidate to
    /// become eligble to become new vault strategy.
    /// @return time in seconds
    ///
    function approvalDelay() external view returns (uint256);

    ///
    /// @dev sets new strategy candidate for the vault
    /// @param strategyCandidate object representing new strategy candidate for vault
    ///
    function proposeStrategy(IFijaStrategy strategyCandidate) external;

    ///
    /// @dev updates strategy in use, based on strategy proposal candidate
    ///
    function updateStrategy() external;
}
