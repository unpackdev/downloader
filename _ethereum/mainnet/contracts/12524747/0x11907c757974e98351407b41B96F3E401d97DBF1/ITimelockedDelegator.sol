// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "./IRing.sol";

/// @title TimelockedDelegator interface
/// @author Ring Protocol
interface ITimelockedDelegator {
    // ----------- Events -----------

    event Delegate(address indexed _delegatee, uint256 _amount);

    event Undelegate(address indexed _delegatee, uint256 _amount);

    // ----------- Beneficiary only state changing api -----------

    function delegate(address delegatee, uint256 amount) external;

    function undelegate(address delegatee) external returns (uint256);

    // ----------- Getters -----------

    function delegateContract(address delegatee)
        external
        view
        returns (address);

    function delegateAmount(address delegatee) external view returns (uint256);

    function totalDelegated() external view returns (uint256);

    function ring() external view returns (IRing);
}
