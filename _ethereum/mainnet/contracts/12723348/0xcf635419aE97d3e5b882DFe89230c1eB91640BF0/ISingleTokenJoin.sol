// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface ISingleTokenJoin {
    struct JoinTokenStruct {
        address inputToken;
        address outputBasket;
        uint256 inputAmount;
        uint256 outputAmount;
        uint256 deadline;
        uint16 referral;
    }

    function joinTokenSingle(JoinTokenStruct calldata _joinTokenStruct)
        external;
}
