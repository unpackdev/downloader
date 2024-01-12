//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";

interface ICODE is IERC20 {
    function claim_delegate(address _delegator, address _delegatee) external;
}
