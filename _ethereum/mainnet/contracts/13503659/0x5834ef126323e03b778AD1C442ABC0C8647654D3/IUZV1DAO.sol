// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IUZV1DAO {
    /* view functions */
    function getLockedTokenCount(address _user) external returns (uint256);
}
