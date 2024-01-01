// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./CheezburgerStructs.sol";

interface ICheezburger is CheezburgerStructs {
    function socialTokens(
        uint256 id
    )
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            address,
            LiquiditySettings calldata,
            DynamicSettings calldata,
            DynamicSettings calldata,
            ReferralSettings calldata
        );

    function withdrawFeesOf(
        uint256 _userId,
        address _to
    ) external returns (uint256);
}
