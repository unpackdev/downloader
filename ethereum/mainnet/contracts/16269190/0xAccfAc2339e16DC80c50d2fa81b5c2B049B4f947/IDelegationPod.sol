// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IPod.sol";

interface IDelegationPod is IPod, IERC20 {
    event Delegated(address account, address delegatee);

    function delegated(address delegator) external view returns(address delegatee);
    function delegate(address delegatee) external;
}
