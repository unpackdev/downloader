// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./IERC20.sol";

/**
 * @title Calculate voting power for VSP holders
 */
contract VesperVotingPowerV3 {
    IERC20 public constant ESVSP = IERC20(0xD02d6eC21851092A9cca8a8eb388fdF66bA96F9B);

    uint256 public constant MINIMUM_VOTING_POWER = 1e18;

    /// @notice Get the voting power for an account
    function balanceOf(address holder_) public view returns (uint256 _votingPower) {
        require(holder_ != address(0), "holder-address-is-zero");

        _votingPower = ESVSP.balanceOf(holder_);

        if (_votingPower < MINIMUM_VOTING_POWER) {
            return 0;
        }
    }
}
