// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./CheezburgerStructs.sol";

interface ICheezburgerFactory is CheezburgerStructs {
    function deployWithToken(
        TokenCustomization memory _customization,
        address _router,
        address _rightSide,
        uint256 _rightSideAmount,
        LiquiditySettings memory _liquidity,
        DynamicSettings memory _fee,
        DynamicSettings memory _wallet,
        ReferralSettings memory _referral
    ) external returns (address);

    function burgerRegistry(
        address token
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
}
