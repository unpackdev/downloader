// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Errors.sol";
import "./IVault.sol";
import "./Clones.sol";
import "./IOperator.sol";

library Generate {
    /// @notice deploys a new clone of `StvAccount`
    /// @param capacityOfStv capacity of the stv
    /// @param manager address of the manager
    /// @param operator address of the operator
    /// @param maxFundraisingPeriod max fundraising period for an stv
    function generate(uint96 capacityOfStv, address manager, address operator, uint40 maxFundraisingPeriod)
        external
        returns (IVault.StvInfo memory stv)
    {
        address stvAccountImplementation = IOperator(operator).getAddress("STVACCOUNT");
        address defaultStableCoin = IOperator(operator).getAddress("DEFAULTSTABLECOIN");

        if (capacityOfStv < 1e6) revert Errors.InputMismatch();

        stv.manager = manager;
        stv.endTime = uint40(block.timestamp) + maxFundraisingPeriod;
        stv.capacityOfStv = capacityOfStv;

        bytes32 salt = keccak256(
            abi.encodePacked(
                manager, defaultStableCoin, capacityOfStv, maxFundraisingPeriod, block.timestamp, block.chainid
            )
        );
        address contractAddress = Clones.cloneDeterministic(stvAccountImplementation, salt);
        stv.stvId = contractAddress;
    }
}
