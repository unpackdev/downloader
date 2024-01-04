   pragma solidity 0.7.0;
// SPDX-License-Identifier: MIT
   
   struct UserInfo{
        address user;
        uint256 balance;
        uint256 approved;
        uint256 offer;
    }

    enum ERR_CODE{
       NO_ERROR,
       FAILED,
       NO_BAC
    }