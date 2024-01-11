// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "./VestingModule.sol";
import "./ClonesWithImmutableArgs.sol";

///
/// @title VestingModuleFactory
/// @author 0xSplits <will@0xSplits.xyz>
/// @notice  A factory contract for cheaply deploying VestingModules.
/// @dev This factory uses our own extension of clones-with-immutable-args to avoid
/// `DELEGATECALL` inside `receive()` to accept hard gas-capped `sends` & `transfers`
/// for maximum backwards composability.
///
contract VestingModuleFactory {
    /// -----------------------------------------------------------------------
    /// errors
    /// -----------------------------------------------------------------------

    error InvalidBeneficiary();
    error InvalidVestingPeriod();

    /// -----------------------------------------------------------------------
    /// libraries
    /// -----------------------------------------------------------------------

    using ClonesWithImmutableArgs for address;

    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    /// @notice New vesting integration contract deployed
    /// @param vestingModule Address of newly created VestingModule clone
    /// @param beneficiary Address to receive funds after vesting
    /// @param vestingPeriod Period of time for funds to vest
    event CreateVestingModule(
        address indexed vestingModule,
        address indexed beneficiary,
        uint256 vestingPeriod
    );

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    VestingModule public implementation;

    /// -----------------------------------------------------------------------
    /// constructor
    /// -----------------------------------------------------------------------

    constructor() {
        implementation = new VestingModule();
    }

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    /// @notice Creates new vesting module
    /// @param beneficiary Address to receive funds after vesting
    /// @param vestingPeriod Period of time for funds to vest
    /// @return vm Address of new vesting module
    function createVestingModule(address beneficiary, uint256 vestingPeriod)
        external
        returns (VestingModule vm)
    {
        /// checks
        if (beneficiary == address(0)) revert InvalidBeneficiary();
        if (vestingPeriod == 0) revert InvalidVestingPeriod();

        /// effects
        bytes memory data = abi.encodePacked(beneficiary, vestingPeriod);
        vm = VestingModule(
            address(implementation).cloneDeterministic(
                bytes32(bytes20(beneficiary)),
                data
            )
        );
        emit CreateVestingModule(address(vm), beneficiary, vestingPeriod);
    }

    /// -----------------------------------------------------------------------
    /// functions - views
    /// -----------------------------------------------------------------------

    /// @notice Predicts address of vesting module & returns whether it already exists
    /// @dev Will return (address(0), false) instead of reverting on invalid inputs
    /// @param beneficiary Address to receive funds after vesting
    /// @param vestingPeriod Period of time for funds to vest
    /// @return predictedAddress Predicted address of new vesting module
    /// @return exists Whether a vesting module already exists at {predictedAddress}
    function predictVestingModuleAddress(
        address beneficiary,
        uint256 vestingPeriod
    ) external view returns (address predictedAddress, bool exists) {
        // TODO: decide if view should revert; leaning toward no
        /// checks
        /* if (beneficiary == address(0)) revert InvalidBeneficiary(); */
        /* if (vestingPeriod == 0) revert InvalidVestingPeriod(); */
        if (beneficiary == address(0) || vestingPeriod == 0)
            return (address(0), false);

        bytes memory data = abi.encodePacked(beneficiary, vestingPeriod);
        (predictedAddress, exists) = address(implementation)
            .predictDeterministicAddress(bytes32(bytes20(beneficiary)), data);
    }
}
