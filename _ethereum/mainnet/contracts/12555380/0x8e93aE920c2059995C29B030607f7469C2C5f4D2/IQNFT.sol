// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IQNFT {
    function qstkBalances(address user) external view returns (uint256);

    function totalAssignedQstk() external view returns (uint256);

    function withdrawETH(address payable multisig) external;
}
