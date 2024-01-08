// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./GovernanceV2.sol";
import "./LoopbackProxy.sol";

/// @title Proposal contract which Governance v1 should execute
contract Proposal {
    // the new governance contract to be upgraded to
    GovernanceV2 public newGovernanceContract;

    /// @notice This function upgrades the LoopbackProxy logic to the GovernanceV2 contract.
    /// @dev the proxy admin is the governance contract itself
    function executeProposal() public {
        newGovernanceContract = new GovernanceV2();

        LoopbackProxy(payable(address(this))).upgradeTo(
            address(newGovernanceContract)
        );

        newGovernanceContract = GovernanceV2(payable(address(this)));

        require(
            stringCompare(newGovernanceContract.version(), "2.vault-migration"),
            "Something went wrong after proxy logic upgrade failed!"
        );

        require(
            newGovernanceContract.deployVault(),
            "Something went wrong with vault deployment!"
        );
    }

    /// @notice This function compares two strings by hashing them to comparable format
    /// @param a first string to compare
    /// @param b second string to compare
    /// @return true if a == b, false otherwise
    function stringCompare(string memory a, string memory b)
        internal
	pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}
