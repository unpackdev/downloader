/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.4;

interface IDODOApproveProxy {
    function claimTokens(address token,address who,address dest,uint256 amount) external;
}
