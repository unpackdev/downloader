// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title An interface for a contract that is capable of deploying Hotpot V3 Funds
/// @notice A contract that constructs a fund must implement this to pass arguments to the fund
/// @dev This is used to avoid having constructor arguments in the fund contract, which results in the init code hash
/// of the fund being constant allowing the CREATE2 address of the fund to be cheaply computed on-chain
interface IHotPotV3FundDeployer {
    /// @notice Get the parameters to be used in constructing the fund, set transiently during fund creation.
    /// @dev Called by the fund constructor to fetch the parameters of the fund
    /// Returns controller The controller address
    /// Returns manager The manager address of this fund
    /// Returns token The local token address
    /// Returns descriptor bytes string descriptor, the first 32 bytes manager name + next bytes brief description
    /// Returns lockPeriod Fund lock up period
    /// Returns baseLine Baseline of fund manager fee ratio
    /// Returns managerFee When the ROI is greater than the baseline, the fund manager’s fee ratio
    function parameters()
        external
        view
        returns (
            address weth9,
            address uniV3Factory,
            address uniswapV3Router,
            address controller,
            address manager,
            address token,
            bytes memory descriptor,
            uint lockPeriod,
            uint baseLine,
            uint managerFee
        );
}
