// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IYieldGenerator {
    enum DefiProtocols {AAVE, COMPOUND, YEARN}

    struct DefiProtocol {
        uint256 targetAllocation;
        uint256 currentAllocation;
        uint256 rebalanceWeight;
        uint256 depositedAmount;
        bool whiteListed;
        bool threshold;
        bool withdrawMax;
    }

    /// @notice deposit stable coin into multiple defi protocols using formulas, access: capital pool
    /// @param amount uint256 the amount of stable coin to deposit
    function deposit(uint256 amount) external returns (uint256);

    /// @notice withdraw stable coin from mulitple defi protocols using formulas, access: capital pool
    /// @param amount uint256 the amount of stable coin to withdraw
    function withdraw(uint256 amount) external returns (uint256);

    /// @notice set the protocol settings for each defi protocol (allocations, whitelisted, threshold), access: owner
    /// @param whitelisted bool[] list of whitelisted values for each protocol
    /// @param allocations uint256[] list of allocations value for each protocol
    /// @param threshold bool[] list of threshold values for each protocol
    function setProtocolSettings(
        bool[] calldata whitelisted,
        uint256[] calldata allocations,
        bool[] calldata threshold
    ) external;

    /// @notice Claims farmed tokens and sends it to the reinsurance pool
    function claimRewards() external;

    /// @notice returns defi protocol info by its index
    /// @param index uint256 the index of the defi protocol
    function defiProtocol(uint256 index) external view returns (DefiProtocol memory _defiProtocol);
}
